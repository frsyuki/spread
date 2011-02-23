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


class TokyoTyrantMDS < MDS
	require 'tokyotyrant'

	MDSSelector.register(:tt, self)

	COL_PK      = ''
	COL_KEY     = '_key'
	COL_VTIME   = '_time'
	COL_RSID    = '_rsid'
	COL_VNAME   = '_vname'
	COL_REMOVED = '_removed'

	COLS_RESERVED = [COL_PK, COL_KEY, COL_VTIME, COL_RSID, COL_VNAME, COL_REMOVED]
	COLS_REQUIRED = [COL_PK, COL_KEY, COL_VTIME, COL_RSID]

	RDBQRY = TokyoTyrant::RDBQRY

	class HADB < BasicHADB
		DEFAULT_PORT = 1978

		FATAL_ERROR = [
			TokyoTyrant::RDB::EINVALID,
			TokyoTyrant::RDB::ENOHOST,
			TokyoTyrant::RDB::EREFUSED,
			TokyoTyrant::RDB::ESEND,
			TokyoTyrant::RDB::ERECV,
			TokyoTyrant::RDB::EMISC
		]

		def open_db(addr)
			db = TokyoTyrant::RDBTBL.new
			db.instance_eval("@enc = 'ASCII-8BIT'")  # FIXME
			unless db.open(*addr)
				$log.warn "failed to connect TokyoTyrant MDS: #{addr}"
			end
			db.setindex(COL_KEY, TokyoTyrant::RDBTBL::ITLEXICAL)
			db
		end

		def ensure_db(db, addr)
			if FATAL_ERROR.include?(db.ecode)
				db.close rescue nil
				db.instance_eval("@ecode = ESUCCESS")  # FIXME
				db.open(*addr)
			end
			return db
		rescue
			return nil
		end

		def error_result?(db, result)
			if FATAL_ERROR.include?(db.ecode)
				return db.errmsg(db.ecode)
			end
			return nil
		end
	end

	def initialize
		@random = Random.new
		@pid = Process.pid
	end

	def open(expr)
		@hadb = HADB.new(expr)
	end

	def close
		@hadb.close
	end

	def get_okey(key, version=nil, &cb)
		map = get_impl(key, version, COLS_RESERVED)
		if map && !is_removed(map)
			okey = to_okey(map)
			cb.call(okey, nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end
	rescue
		cb.call(nil, $!) rescue nil
	end

	def get_attrs(key, version=nil, &cb)
		map = get_impl(key, version)
		if map && !is_removed(map)
			attrs = to_attrs(map)
			cb.call(attrs, nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end
	rescue
		cb.call(nil, $!) rescue nil
	end

	def get_okey_attrs(key, version=nil, &cb)
		map = get_impl(key, version)
		if map && !is_removed(map)
			okey = to_okey(map)
			attrs = to_attrs(map)
			cb.call([okey, attrs], nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end
	rescue
		cb.call(nil, $!) rescue nil
	end

	def add(key, attrs={}, vname=nil, &cb)
		okey = add_impl(key, attrs, vname)
		cb.call(okey, nil) rescue nil
	rescue
		cb.call(nil, $!) rescue nil
	end

	def update_attrs(key, attrs, &cb)
		okey = update_impl(key) {|old_attrs|
			attrs
		}
		cb.call(okey, nil) rescue nil
	rescue
		cb.call(nil, $!) rescue nil
	end

	#def merge_attrs(key, attrs, &cb)
	#	okey = update_impl(key) {|old_attrs|
	#		old_attrs.merge(attrs)
	#	}
	#	cb.call(okey, nil) rescue nil
	#rescue
	#	cb.call(nil, $!) rescue nil
	#end

	def remove(key, &cb)
		map = get_impl_head(key, COLS_REQUIRED)
		if map && !is_removed(map)
			# optional: inherit rsid
			rsid = map[COL_RSID].to_i

			# get current vtime later than old vtime
			vtime = get_current_vtime(map[COL_VTIME].to_i)

			okey = new_okey(key, vtime, rsid)

			# insert
			pk = new_pk(map[COL_PK])
			map = to_map({}, okey, nil, true)
			@hadb.write(key) {|rdb| rdb.put(pk, map) }

			okey = to_okey(map)
			cb.call(okey, nil) rescue nil

		else
			cb.call(nil, nil) rescue nil
		end

	rescue
		cb.call(nil, $!) rescue nil
	end

	def util_locate(key, &cb)
		array = @hadb.read(key) {|rdb|
			qry = RDBQRY.new(rdb)
			qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
			qry.searchget(COLS_RESERVED)
		}

		array.reject! {|map|
			!is_valid_map(map) || is_removed(map)
		}

		array.map! {|map|
			[to_okey(map), map[COL_VNAME]]
		}

		cb.call(array, nil) rescue nil

	rescue
		cb.call(nil, $!) rescue nil
	end

	private
	def to_okey(map)
		key = map[COL_KEY]
		rsid = map[COL_RSID].to_i
		vtime = map[COL_VTIME].to_i
		new_okey(key, vtime, rsid)
	end

	def to_attrs(map)
		map.reject {|k,v| COLS_RESERVED.include?(k) }
	end

	def to_map(attrs, okey, vname=nil, removed=false)
		map = attrs.dup
		map.delete(COL_PK)
		map[COL_KEY] = okey.key
		map[COL_RSID] = okey.rsid.to_s
		map[COL_VTIME] = okey.vtime.to_s
		if vname
			map[COL_VNAME] = vname.to_s
		end
		if removed
			map[COL_REMOVED] = "1"
		end
		map
	end

	def get_impl(key, version=nil, cols=nil)
		if version == nil
			get_impl_head(key, cols)
		elsif version.is_a?(String)
			get_impl_vname(key, version, cols)
		else
			get_impl_vtime(key, version, cols)
		end
	end

	def get_impl_head(key, cols=nil)
		map = @hadb.read(key) {|rdb|
			qry = RDBQRY.new(rdb)
			qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
			qry.setorder(COL_VTIME, RDBQRY::QONUMDESC)
			qry.setlimit(1)
			array = qry.searchget(cols)
			array[0]
		}

		if map == nil
			return nil
		elsif !is_valid_map(map)
			return nil
		else
			return map
		end
	end

	def get_impl_vname(key, vname, cols=nil)
		map = @hadb.read(key) {|rdb|
			qry = RDBQRY.new(rdb)
			qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
			qry.addcond(COL_VNAME, RDBQRY::QCSTREQ, vname)
			qry.setorder(COL_VTIME, RDBQRY::QONUMDESC)
			qry.setlimit(1)
			array = qry.searchget(cols)
			array[0]
		}

		if map == nil
			return nil
		elsif !is_valid_map(map)
			return nil
		else
			return map
		end
	end

	def get_impl_vtime(key, vtime, cols)
		map = @hadb.read(key) {|rdb|
			qry = RDBQRY.new(rdb)
			qry.addcond(COL_KEY, RDBQRY::QCSTREQ, key)
			qry.addcond(COL_VTIME, RDBQRY::QCNUMLE, vtime.to_s)
			qry.setorder(COL_VTIME, RDBQRY::QONUMDESC)
			qry.setlimit(1)
			array = qry.searchget(cols)
			array[0]
		}

		if map == nil
			return nil
		elsif !is_valid_map(map)
			return nil
		else
			return map
		end
	end

	#def select_latest_valid(array)
	#	latest = select_latest(array)
	#	if is_valid_map(latest)
	#		return latest
	#	else
	#		return nil
	#	end
	#end

	#def select_latest(array)
	#	if array.size == 1
	#		return array[0]
	#	end
	#
	#	max_vtime = 0
	#	marray = []
	#
	#	array.each {|map|
	#		vtime = map[COL_VTIME].to_i
	#		if max_vtime < vtime
	#			marray.clear
	#			marray << map
	#			max_vtime = vtime
	#		elsif max_vtime == vtime
	#			marray << map
	#		end
	#	}
	#
	#	if marray.size == 1
	#		return marray[0]
	#	else
	#		return marray.sort_by {|map| map[COL_PK] }.last
	#	end
	#end

	def is_valid_map(map)
		COLS_REQUIRED.all? {|col| map.has_key?(col) }
	end

	def is_removed(map)
		map.has_key?(COL_REMOVED)
	end

	def add_impl(key, attrs, vname=nil)
		map = get_impl_head(key, COLS_REQUIRED)

		if map
			# optional: inherit rsid
			rsid = map[COL_RSID].to_i

			# get current vtime later than old vtime
			vtime = get_current_vtime(map[COL_VTIME].to_i)

			okey = new_okey(key, vtime, rsid)

			# insert
			pk = new_pk(map[COL_PK])
			map = to_map(attrs, okey, vname)
			@hadb.write(key) {|rdb| rdb.put(pk, map) }

		else
			attrs ||= {}

			okey = new_okey(key)

			# insert
			pk = new_pk()
			map = to_map(attrs, okey, vname)
			@hadb.write(key) {|rdb| rdb.put(pk, map) }
		end

		return okey
	end

	def update_impl(key, &modifier)
		map = get_impl_head(key, nil)

		if map && !is_removed(map)
			okey = to_okey(map)

			# create new attrs
			attrs = modifier.call( to_attrs(map) )

			# reject old attributes
			map.reject! {|k,v| !COLS_RESERVED.include?(k) }

			# merge new attributes
			map = attrs.merge(map)

			# update
			pk = map.delete(COL_PK)
			@hadb.write(key) {|rdb| rdb.put(pk, map) }

			return okey

		else
			return nil
		end
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
	def new_pk(at_least=nil)
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

		gid = @pid

		r = @random.rand(2**16)
		raw = [sec<<2|msec>>8, msec&0xff, r, gid].pack('NCnC')

		# FIXME base64
		raw = [raw].pack('m')
		raw.gsub!(/[\n\=]+/,'')
		raw
	end
end


end
