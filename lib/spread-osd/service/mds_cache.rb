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


class MDSCacheBus < Bus
	call_slot :get
	call_slot :set
	call_slot :invalidate
end


class MDSCacheConfigService < Service
	def run
		@uri = ConfigBus.get_initial_mds_cache_uri
		@uri ||= "null"
		on_change
	end

	def rpc_get_mds_cache_uri
		@uri
	end

	def rpc_set_mds_cache_uri(uri)
		@uri = uri
		on_change
		nil
	end

	def self.hash_uri(uri)
		Digest::SHA1.digest(uri)
	end

	def on_change
		SyncBus.update(SYNC_MDS_CACHE_URI,
							@uri, MDSCacheConfigService.hash_uri(@uri))
	end

	ebus_connect :ProcessBus,
		:run

	ebus_connect :CSRPCBus,
		:get_mds_cache_uri => :rpc_get_mds_cache_uri,
		:set_mds_cache_uri => :rpc_set_mds_cache_uri
end


class MDSCacheService < Service
	def initialize
		@uri = ""
		@cache = NullMDSCache.new
	end

	def run
		SyncBus.register_callback(SYNC_MDS_CACHE_URI,
							MDSCacheConfigService.hash_uri(@uri)) do |obj|
			uri = obj
			reopen(uri)
			@uri = uri
			MDSCacheConfigService.hash_uri(@uri)
		end
	end

	def shutdown
		if @cache
			@cache.close rescue nil
		end
	end

	def reopen(uri)
		klass, expr = MDSCacheSelector.select_class(uri)

		cache = klass.new
		cache.open(expr)

		old_cache = @cache
		@cache = cache

		$log.info "using MDS cache: #{@cache}"

		begin
			old_cache.close
		rescue
			$log.error "MDSCache close error: #{$!}"
			$log.error $!.backtrace.pretty_inspect
		end
	end

	ebus_connect :ProcessBus,
		:run,
		:shutdown

	ebus_connect :MDSCacheBus,
		:get,
		:set,
		:invalidate

	extend Forwardable

	def_delegators :@cache,
		:get,
		:set,
		:invalidate
end


module MDSCacheSelector
	IMPLS = {}

	def self.register(name, klass)
		IMPLS[name.to_sym] = klass
		nil
	end

	def self.select_class(uri)
		if uri.empty?
			return NullMDSCacheService
		end

		if m = /^(\w{1,8})\:(.*)/.match(uri)
			type = m[1].to_sym
			expr = m[2]
		else
			type = :null
			expr = uri
		end

		klass = IMPLS[type]
		unless klass
			raise "unknown MDSCache type: #{type}"
		end

		return klass, expr
	end
end


class MDSCache
	#def open(expr)
	#end

	#def close
	#end

	#def get(key)
	#end

	#def set(key, val)
	#end

	#def invalidate(key)
	#end
end


class NullMDSCache < MDSCache
	MDSCacheSelector.register(:null, self)

	def open(expr)
	end

	def close
	end

	def get(key)
		nil
	end

	def set(key, val)
	end

	def invalidate(key)
	end

	def to_s
		"no-cache"
	end
end


class CachedMDSBus < Bus
	call_slot :get_okey
	call_slot :get_attrs
	call_slot :get_okey_attrs
	call_slot :add
	call_slot :update_attrs
	call_slot :remove
	call_slot :util_locate
end


class CachedMDSService < Service
	def get_okey(key, version=nil, &cb)
		if version == nil
			if okey = get_cache(key)
				return okey
			end
		end
		MDSBus.get_okey(key, version) {|okey,error|
			set_cache(key, okey) if okey
			cb.call(okey, error)
		}
	end

	def get_attrs(key, version=nil, &cb)
		MDSBus.get_attrs(key, version, &cb)
	end

	def get_okey_attrs(key, version=nil, &cb)
		MDSBus.get_okey_attrs(key, version, &cb)
	end

	def add(key, attrs={}, vname=nil, &cb)
		invalidate_cache(key)
		MDSBus.add(key, attrs, vname, &cb)
	end

	def update_attrs(key, attrs, &cb)
		invalidate_cache(key)
		MDSBus.update_attrs(key, attrs, &cb)
	end

	def remove(key, &cb)
		invalidate_cache(key)
		MDSBus.remove(key, &cb)
	end

	def util_locate(key, &cb)
		MDSBus.util_locate(key, &cb)
	end

	ebus_connect :CachedMDSBus,
		:get_okey,
		:get_attrs,
		:get_okey_attrs,
		:add,
		:update_attrs,
		:remove,
		:util_locate

	private
	def get_cache(key)
		if val = MDSCacheBus.get(key)
			rsid, vtime = MessagePack.unpack(val)
			return ObjectKey.new(key, vtime, rsid)
		end
		return nil
	rescue
		$log.warn("error when getting MDS cache: key=#{key.inspect}: #{$!.to_s}")
		$log.debug_backtrace $!.backtrace
		return nil
	end

	def set_cache(key, okey)
		val = [okey.rsid, okey.vtime].to_msgpack
		MDSCacheBus.set(key, val)
	rescue
		$log.warn("error when setting MDS cache: key=#{key.inspect}: #{$!.to_s}")
		$log.debug_backtrace $!.backtrace
	end

	def invalidate_cache(key)
		MDSCacheBus.invalidate(key)
	rescue
		$log.warn("error when invalidating MDS cache: key=#{key.inspect}: #{$!.to_s}")
		$log.debug_backtrace $!.backtrace
	end
end


end
