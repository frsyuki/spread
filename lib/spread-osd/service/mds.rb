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


class MDSBus < Bus
	call_slot :open
	call_slot :close

	# @return
	#   found: ObjectKey
	#   not found: nil
	call_slot :get_okey

	# @return
	#   found: Hash (may be {})
	#   not found: nil
	call_slot :get_attrs

	# @return
	#   found: [ObjectKey, Hash (may be {})]
	#   not found: [nil, nil]
	call_slot :get_okey_attrs

	# @return new ObjectKey or existent ObjectKey
	call_slot :set_okey

	# @return new ObjectKey or existent ObjectKey
	call_slot :set_okey_attrs

	# @return
	#   found and removed: true
	#   not found: nil
	call_slot :remove

	# @return array
	call_slot :select
end


=begin
# TODO
class MDSConfigService < Service
	def run
		@uri = ConfigBus.get_mds_uri
	end
end


class MDSConfigService < Service
	def on_change
		HeartbeatBus.update_sync_config(CONFIG_SYNC_SNAPSHOT,
							@slist, @slist.get_hash)
	end
end


class MDSSelectorService < Service
	def initialize
	end

	def run
		HeartbeatBus.register_sync_config(CONFIG_SYNC_SNAPSHOT,
							@slist.get_hash) do |obj|
			@slist.from_msgpack(obj)
			on_change
			@slist.get_hash
		end
	end

	def open!
	end
end
=end


module MDSSelector
	IMPLS = {}

	def self.register(name, klass)
		IMPLS[name.to_sym] = klass
		nil
	end

	def self.select_class(uri)
		if m = /^(\w{1,8})\:(.*)/.match(uri)
			type = m[1].to_sym
			expr = m[2]
		else
			type = :tt
			expr = uri
		end

		klass = IMPLS[type]
		unless klass
			raise "unknown MDS type: #{type}"
		end

		return klass, expr
	end

	def self.select!(uri)
		klass, expr = select_class(uri)
		klass.bind!

		MDSBus.open(expr)
	end

	def self.reselect!(uri)
		klass, expr = select_class(uri)
		MDSBus.ebus_disconnect!
		klass.bind!

		MDSBus.open(expr)
	end

	def self.open!
		cs_address = ConfigBus.get_cs_address
		uri = ProcessBus.get_session(cs_address).call(:get_mds_uri)
		select!(uri)
	end
end


class MDSService < Service
	module Query
		QC_EQ                = 0
		QC_NOT_EQ            = 1
		QC_LESS_THAN         = 2
		QC_LESS_THAN_EQ      = 3
		QC_GRATER_THAN       = 4
		QC_GRATER_THAN_EQ    = 5
		QC_NULL              = 6
		QC_NOT_NULL          = 8

		ORDER_NONE           = 0
		ORDER_STR_ASC        = 1
		ORDER_STR_DESC       = 2
		ORDER_NUM_ASC        = 3
		ORDER_NUM_DESC       = 4
	end

	#def open(expr)
	#end

	#def close
	#end

	#def get_okey(sid, key=nil, &cb)
	#end

	#def get_attrs(sid, key=nil, &cb)
	#end

	#def get_okey_attrs(sid, key=nil, &cb)
	#end

	#def set_okey(key, &cb)
	#end

	#def set_okey_attrs(key, attrs, &cb)
	#end

	#def remove(key, &cb)
	#end

	def select(cols, conds, order, order_col, limit, skip, sid=nil)
		raise "select is not supported on MDS"
	end

	ebus_connect :MDSBus,
		:get_okey,
		:get_attrs,
		:get_okey_attrs,
		:set_okey,
		:set_okey_attrs,
		:remove,
		:select,
		:open,
		:close

	def shutdown
		MDSBus.close
	end

	ebus_connect :ProcessBus,
		:shutdown

	protected
	def new_okey(key, sid=get_current_sid, rsid=nil)
		rsid ||= BalanceBus.select_next_rsid(key)
		ObjectKey.new(key, sid, rsid)
	end

	def get_current_sid
		SnapshotBus.get_current_sid
	end
end


end
