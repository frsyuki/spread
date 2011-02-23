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

	# @return new ObjectKey
	call_slot :add

	# @return
	#   found: updated ObjectKey
	#   not found: nil
	call_slot :update_attrs

	# @return
	#   found: removed ObjectKey
	#   not found: nil
	call_slot :remove

	# @return
	#   found: removed ObjectKey
	#   not found: nil
	call_slot :delete

	# @return
	#   found: array of [ObjectKey, vtime, vname]
	#   not found: []
	call_slot :util_locate
end


class MDSConfigService < Service
	def run
		@uri = ConfigBus.get_initial_mds_uri
		on_change
	end

	def rpc_get_mds_uri
		@uri
	end

	def rpc_set_mds_uri(uri)
		@uri = uri
		on_change
		nil
	end

	def self.hash_uri(uri)
		Digest::SHA1.digest(uri)
	end

	def on_change
		SyncBus.update(SYNC_MDS_URI,
							@uri, MDSConfigService.hash_uri(@uri))
	end

	ebus_connect :ProcessBus,
		:run

	ebus_connect :CSRPCBus,
		:get_mds_uri => :rpc_get_mds_uri,
		:set_mds_uri => :rpc_set_mds_uri
end


class MDSService < Service
	def initialize
		@uri = ""
		@mds = NullMDS.new
	end

	def run
		SyncBus.register_callback(SYNC_MDS_URI,
							MDSConfigService.hash_uri(@uri)) do |obj|
			uri = obj
			reopen(uri)
			@uri = uri
			MDSConfigService.hash_uri(@uri)
		end
	end

	def shutdown
		if @mds
			@mds.close rescue nil
		end
	end

	def reopen(uri)
		klass, expr = MDSSelector.select_class(uri)

		mds = klass.new
		mds.open(expr)

		old_mds = @mds
		@mds = mds

		$log.info "using MDS: #{@mds}"

		begin
			old_mds.close
		rescue
			$log.error "MDS close error: #{$!}"
			$log.error_backtrace $!.backtrace
		end
	end

	ebus_connect :ProcessBus,
		:run,
		:shutdown

	ebus_connect :MDSBus,
		:get_okey,
		:get_attrs,
		:get_okey_attrs,
		:add,
		:update_attrs,
		:remove,
		:delete,
		:util_locate

	extend Forwardable

	def_delegators :@mds,
		:get_okey,
		:get_attrs,
		:get_okey_attrs,
		:add,
		:update_attrs,
		:remove,
		:delete,
		:util_locate
end


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
end


class MDS
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

	# @param version vname:String or vtime:Integer
	#def get_okey(key, version=nil, &cb)
	#end

	# @param version vname:String or vtime:Integer
	#def get_attrs(key, version=nil, &cb)
	#end

	# @param version vname:String or vtime:Integer
	#def get_okey_attrs(key, version=nil, &cb)
	#end

	#def add(key, attrs={}, vname=nil, &cb)
	#end

	#def update_attrs(key, attrs, &cb)
	#end

	#def remove(key, &cb)
	#end

	#def delete(key, version=nil, &cb)
	#end

	def util_locate(key, &cb)
		get_okey(key) {|okey|
			if okey
				cb.call([okey, nil], nil) rescue nil
			else
				cb.call([], nil) rescue nil
			end
		}
	end

	protected
	def get_current_vtime(at_least=0)
		now = Time.now.utc.to_i
		if now <= at_least
			return at_least + 1
		else
			return now
		end
	end

	def new_okey(key, vtime=get_current_vtime, rsid=nil)
		rsid ||= BalanceBus.select_next_rsid(key)
		ObjectKey.new(key, vtime, rsid)
	end
end


class NullMDS < MDS
	extend Forwardable

	[
		:get_okey,
		:get_attrs,
		:get_okey_attrs,
		:add,
		:remove,
		:delete,
		:util_locate,
		:open
	].each {|method|
		def_delegator :self, :raise_error, method
	}

	def raise_error(*args)
		raise "mds is not configured"
	end

	def close
	end
end


end
