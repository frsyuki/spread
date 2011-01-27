#
#  SpreadOSD
#  Copyright (C) 2010  FURUHASHI Sadayuki
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module SpreadOSD


#
# Table database:
#
# pk => {_key:key, _rsid:rsid, _min:sid, _max:sid, attrs}
#
# get(key)
#   select * where (_key == key) and (_max is not set)
#   if found.size > 1
#     make_consistency(key, sorted)
#   end
#
# get_snapshot(key, sid)
#   select * where (_key == key) and _min < sid and !(_max < sid)
#
# set(key, attrs)
#   select * where (_key == key) and !(_max < current_sid)
#   if not found
#     attrs ||= {}
#     pk = new_oid
#     rsid = new_rsid
#     insert pk (_key:key, _rsid:rsid, _min:current_sid, attrs)
#   else
#     if _max is not set
#       attrs ||= _attrs
#     end
#     pk = new_oid at_least _oid
#     rsid = _rsid
#     insert pk (_key:key, _rsid:rsid, _min:current_sid, attrs)
#     if _min == current_sid
#       remove _oid
#     else
#       update:putcat _oid (_max:current_sid)
#     end
#   end
#
# remove(key)
#   get(key)
#   if found
#     update:putcat _oid (_max:current_sid)
#   end
#
# make_consistency(key, sorted)
#   sorted = sort_by(_oid)
#   selected = sorted.remove_first
#   used = [selected._min]
#   sorted.each {|x|
#     if used.include?(x._min)
#       remove x._oid
#     else
#       update:putcat x._oid (_max:selected._min)
#       used << x._oid
#     end
#   }
#   return selected
#
#
class TokyoTyrantMDS < MDS
	MDSSelector.register(:tt, self)

	DEFAULT_PORT = 1978

	COL_PK   = ''
	COL_KEY  = '_key'
	COL_MIN  = '_min'
	COL_MAX  = '_max'
	COL_RSID = '_rsid'

	COLS_RESERVED = [COL_PK, COL_KEY, COL_MIN, COL_MAX, COL_RSID]
	COLS_RESERVED_NOKEY = [COL_PK, COL_MIN, COL_MAX, COL_RSID]
	COLS_REQUIRED = [COL_PK, COL_KEY, COL_MIN, COL_RSID]

	RDBQRY = TokyoTyrant::RDBQRY

	FATAL_ERROR = [
		TokyoTyrant::RDB::EINVALID,
		TokyoTyrant::RDB::ENOHOST,
		TokyoTyrant::RDB::EREFUSED,
		TokyoTyrant::RDB::ESEND,
		TokyoTyrant::RDB::ERECV
	]

	def initialize
		@random = Random.new
		@pid = Process.pid
	end

	def open(expr)
		@rdb = TokyoTyrant::RDBTBL.new
		@rdb.instance_eval("@enc = 'ASCII-8BIT'")  # FIXME
		@host, @port = expr.split(':', 2)
		@port ||= DEFAULT_PORT
		unless @rdb.open(@host, @port)
			raise "failed to open TokyoTyrant MDS: #{errmsg}"
		end
	end

	def close
		@rdb.close
	end

	def try_reopen
		if FATAL_ERROR.include?(@rdb.ecode)
			@rdb.close rescue nil
			@rdb.open(@host, @port)
		end
	rescue
		nil
	end

	def get_okey(key, sid=nil, &cb)
		map = get_impl(key, sid, COLS_REQUIRED)
		if map
			okey = to_okey(map)
			cb.call(okey, nil)
		else
			cb.call(nil, nil)
		end
	rescue
		cb.call(nil, $!)
	end

	def get_attrs(key, sid=nil, &cb)
		map = get_impl(key, sid)
		if map
			attrs = to_attrs(map)
			cb.call(attrs, nil)
		else
			cb.call(nil, nil)
		end
	rescue
		cb.call(nil, $!)
	end

	def get_okey_attrs(key, sid=nil, &cb)
		map = get_impl(key, sid)
		if map
			okey = to_okey(map)
			attrs = to_attrs(map)
			cb.call([okey, attrs], nil)
		else
			cb.call(nil, nil)
		end
	rescue
		cb.call(nil, $!)
	end

	def set_okey(key, &cb)
		okey = set_impl(key)
		cb.call(okey, nil)
	rescue
		cb.call(nil, $!)
	end

	def set_okey_attrs(key, attrs, &cb)
		okey = set_impl(key, attrs)
		cb.call(okey, nil)
	rescue
		cb.call(nil, $!)
	end

	def remove(key, &cb)
		map = get_impl_head(key, COLS_REQUIRED)
		if map
			sid = get_current_sid
			unless @rdb.putcat(map[COL_PK], {COL_MAX => sid})
				try_reopen
				raise "putcat failed: #{errmsg}"
			end
			okey = to_okey(map)
			cb.call(okey, nil)
		else
			cb.call(nil, nil)
		end
	rescue
		cb.call(nil, $!)
	end

	def select(cols, conds, order, order_col, limit, skip, sid=nil, &cb)
		qry = RDBQRY.new(@rdb)
		if sid
			qry.addcond(COL_MIN, RDBQRY::QCNUMLT, sid.to_s)
			qry.addcond(COL_MAX, RDBQRY::QCNUMLT|RDBQRY::QCNEGATE, sid.to_s)
		else
			qry.addcond(COL_MAX, RDBQRY::QCNUMGE|RDBQRY::QCNEGATE, 0.to_s)
		end

		conds.each {|col,op,*args|
			case op
			when Query::QC_EQ
				rval = select_cond_check_num(:EQ, args, 1)
				if rval.is_a?(String)
					qry.addcond(col, RDBQRY::QCSTREQ, rval.to_s)
				elsif rval.is_a?(Numeric)
					qry.addcond(col, RDBQRY::QCNUMEQ, rval.to_s)
				else
					select_cond_check_type(:EQ, rval, nil)
				end

			when Query::QC_NOT_EQ
				rval = select_cond_check_num(:NEQ, args, 1)
				if rval.is_a?(String)
					qry.addcond(col, RDBQRY::QCSTREQ|RDBQRY::QCNEGATE, rval.to_s)
				elsif rval.is_a?(Numeric)
					qry.addcond(col, RDBQRY::QCNUMEQ|RDBQRY::QCNEGATE, rval.to_s)
				else
					select_cond_check_type(:NEQ, rval, nil)
				end

			when Query::QC_LESS_THAN
				rval = select_cond_check_num(:LT, args, 1)
				select_cond_check_type(:LT, rval, Numeric)
				qry.addcond(col, RDBQRY::QCNUMLT, rval.to_s)

			when Query::QC_LESS_THAN_EQ
				rval = select_cond_check_num(:LE, args, 1)
				select_cond_check_type(:LE, rval, Numeric)
				qry.addcond(col, RDBQRY::QCNUMLE, rval.to_s)

			when Query::QC_GRATER_THAN
				rval = select_cond_check_num(:GT, args, 1)
				select_cond_check_type(:GT, rval, Numeric)
				qry.addcond(col, RDBQRY::QCNUMGT, rval.to_s)

			when Query::QC_GRATER_THAN_EQ
				rval = select_cond_check_num(:GE, args, 1)
				select_cond_check_type(:GE, rval, Numeric)
				qry.addcond(col, RDBQRY::QCNUMGE, rval.to_s)

			when Query::QC_NULL
				select_cond_check_num(:NULL, args, 0)
				qry.addcond(col, RDBQRY::QCSTRBW|RDBQRY::QCNUMGE, "")  # !(begin with "")

			when Query::QC_NOT_NULL
				select_cond_check_num(:NNULL, args, 0)
				qry.addcond(col, RDBQRY::QCSTRBW, "")  # begin with ""

			else
				raise "unknown condition operator: #{op}"
			end
		}

		case order
		when nil, Query::ORDER_NONE
			#
		when Query::ORDER_STR_ASC
			qry.setorder(order_col, RDBQRY::QOSTRASC)
		when Query::ORDER_STR_DESC
			qry.setorder(order_col, RDBQRY::QOSTRDESC)
		when Query::ORDER_NUM_ASC
			qry.setorder(order_col, RDBQRY::QONUMASC)
		when Query::ORDER_NUM_DESC
			qry.setorder(order_col, RDBQRY::QONUMDESC)
		else
			raise "unknown order: #{order}"
		end

		limit = -1 if !limit || limit < 0
		skip  = -1 if !skip  || skip < 0
		if limit >= 0 || skip >= 0
			qry.setlimit(limit, skip)
		end

		#if cols
		#	cols = cols + [COL_KEY, COL_MIN, COL_RSID]
		#end
		array = qry.searchget(cols)

		if array.empty?
			try_reopen
		end

		result = array.map {|map|
			to_attrs_and_key(map)
		}

		cb.call(result, nil)

	rescue
		cb.call(nil, $!)
	end

	private
	def select_cond_check_num(op, args, num=nil)
		if !num || args.length != num
			raise "invalid arguments for operator #{op}: #{args}"
		end
		if num == 1
			args[0]
		else
			args
		end
	end

	def select_cond_check_type(op, val, type=nil)
		if !type || !val.is_a?(type)
			raise "invalid argument type for operator #{op}: #{val} (#{rtype_mtype(val)})"
		end
	end

	def rtype_mtype(val)
		case val.class
		when Hash
			"Map"
		when Array
			"Array"
		when String
			"String"
		when Float
			"Float"
		when Integer
			"Integer"
		when NilClass
			"Nil"
		when TrueClass, FalseClass
			"Boolean"
		else
			"Unknown"
		end
	end

	private
	def errmsg
		@rdb.errmsg(@rdb.ecode)
	end

	def to_okey(map)
		rsid = map[COL_RSID].to_i
		min = map[COL_MIN]
		min = min.to_i if min
		new_okey(map[COL_KEY], min, rsid)
	end

	def to_attrs(map)
		map.reject {|k,v| COLS_RESERVED.include?(k) }
	end

	def to_attrs_and_key(map)
		map.reject {|k,v| COLS_RESERVED_NOKEY.include?(k) }
	end

	def to_map(attrs, okey)
		map = attrs.dup
		map.delete(COL_PK)
		map[COL_KEY] = okey.key
		map[COL_RSID] = okey.rsid.to_s
		map[COL_MIN] = okey.sid.to_s
		map
	end

	def make_consistency(array)
		sorted = array.sort_by {|x| x[COL_PK] }
		# TODO
		sorted.last
	end

	def get_impl_head(key, cols)
		qry = RDBQRY.new(@rdb)
		qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
		qry.addcond(COL_MAX, RDBQRY::QCSTRBW|RDBQRY::QCNEGATE, "")
		array = qry.searchget(cols)
		array.reject! {|map| is_invalid_map(map) }

		if array.empty?
			try_reopen
			return nil
		elsif array.size == 1
			return array[0]
		else
			return make_consistency(array)
		end
	end

	def get_impl_sid(key, sid, cols)
		qry = RDBQRY.new(@rdb)
		qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
		qry.addcond(COL_MIN, RDBQRY::QCNUMLT, sid.to_s)
		qry.addcond(COL_MAX, RDBQRY::QCNUMLT|RDBQRY::QCNEGATE, sid.to_s)
		array = qry.searchget(cols)
		array.reject! {|map| is_invalid_map(map) }

		if array.empty?
			try_reopen
			return nil
		else
			return array[0]
		end
	end

	def get_impl(key, sid=nil, cols=nil)
		if sid == nil
			get_impl_head(key, cols)
		else
			get_impl_sid(key, sid, cols)
		end
	end

	def is_invalid_map(map)
		COLS_REQUIRED.find {|col| !map.has_key?(col) }
	end

	def set_impl(key, attrs=nil)
		sid = get_current_sid
		qry = RDBQRY.new(@rdb)
		qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
		qry.addcond(COL_MAX, RDBQRY::QCNUMLE|RDBQRY::QCNEGATE, sid.to_s)
		array = qry.searchget
		array.reject! {|map| is_invalid_map(map) }

		if array.empty?
			try_reopen
			attrs ||= {}
			okey = new_okey(key, sid)
			pk = gen_pk(okey.rsid)
			unless @rdb.put(pk, to_map(attrs, okey))
				try_reopen
				raise "put failed: #{errmsg}"
			end

		else
			map = array.find {|map| map[COL_MAX] == nil }
			if map
				# inherit attrs
				attrs ||= to_attrs(map)
			else
				attrs ||= {}
				sorted = array.sort_by {|x| x[COL_PK] }
				map = sorted.last
			end

			# inherit rsid
			rsid = map[COL_RSID].to_i

			okey = new_okey(key, sid, rsid)

			# don't inherit pk
			pk = gen_pk(okey.rsid, map[COL_PK])

			unless @rdb.put(pk, to_map(attrs, okey))
				try_reopen
				raise "put failed #{errmsg}"
			end

			if map[COL_MIN].to_i == sid
				# ignore error : leave inconsistency
				unless @rdb.out(map[COL_PK])
					try_reopen
				end
			elsif map[COL_MAX] == nil
				# ignore error : leave inconsistency
				unless @rdb.putcat(map[COL_PK], {COL_MAX=>sid})
					try_reopen
				end
			end
		end

		return okey
	end

	# +----------+----+------+---+
	# |    30    | 10 |  16  | 8 |
	# +----------+----+------+---+
	# UNIX time
	#            millisec
	#                 rand
	#                        generator-id
	# +--------------------------+
	#            64 bits
	#
	def gen_pk(rsid, at_least=nil)
		nowtime = Time.now.utc
		sec = nowtime.sec
		msec = nowtime.usec / 1000

		if at_least && at_least.size == 8
			time_u, time_d = at_least.unpack('NC')
			asec = time_u>>2
			amsec = (time_u&0x3)<<2 & time_d
			if sec < asec || (sec == asec && msec <= amsec)
				sec = asec + 1
				msec = amsec
			end
		end

		gid = rsid | @pid

		r = @random.rand(2**16)
		raw = [sec<<2|msec>>8, msec&0xff, r, gid].pack('NCnC')

		# FIXME base64
		raw = [raw].pack('m')
		raw.gsub!(/[\n\=]+/,'')
		raw
	end
end


end
