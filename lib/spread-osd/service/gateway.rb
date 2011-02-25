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


class GatewayService < Service
	def rpc_get(key)
		rpc_get_impl(nil, key)
	end

	def rpc_get_data(key)
		rpc_get_data_impl(nil, key)
	end

	def rpc_get_attrs(key)
		rpc_get_attrs_impl(nil, key)
	end

	def rpc_read(key, offset, size)
		rpc_read_impl(nil, key, offset, size)
	end


	def rpc_gett(vtime, key)
		rpc_get_impl(vtime, key)
	end

	def rpc_gett_data(vtime, key)
		rpc_get_data_impl(vtime, key)
	end

	def rpc_gett_attrs(vtime, key)
		rpc_get_attrs_impl(vtime, key)
	end

	def rpc_readt(vtime, key, offset, size)
		rpc_read_impl(vtime, key, offset, size)
	end


	def rpc_getv(vname, key)
		rpc_get_impl(vname, key)
	end

	def rpc_getv_data(vname, key)
		rpc_get_data_impl(vname, key)
	end

	def rpc_getv_attrs(vname, key)
		rpc_get_attrs_impl(vname, key)
	end

	def rpc_readv(vname, key, offset, size)
		rpc_read_impl(vname, key, offset, size)
	end


	def rpc_get_impl(version, key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.get_okey_attrs(key, version) {|(okey,attrs),error|
			if error
				$log.warn("failed to get a key or attributes from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.get(okey, true) {|data,error|
					if error
						$log.warn(error)
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					#data ||= ""
					ar.result([data,attrs])
				}
			else
				ar.result([nil,nil])
			end
		}
		ar
	end

	def rpc_get_data_impl(version, key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.get_okey(key, version) {|okey,error|
			if error
				$log.warn("failed to get a key from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.get(okey, true) {|data,error|
					if error
						$log.warn(error)
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					#data ||= ""
					ar.result(data, nil)
				}
			else
				ar.result(nil)
			end
		}
		ar
	end

	def rpc_get_attrs_impl(version, key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.get_attrs(key, version) {|attrs,error|
			if error
				$log.warn("failed to get attributes from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif attrs
				ar.result(attrs)
			else
				ar.result(nil)
			end
		}
		ar
	end

	def rpc_read_impl(version, key, offset, size)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.get_okey(key, version) {|okey,error|
			if error
				$log.warn("failed to get a key from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.read(okey, offset, size, true) {|data,error|
					if error
						$log.warn("failed to get data from DS: key=#{key.inspect}: #{error} rsid=#{okey.rsid}")
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					#data ||= ""
					ar.result(data)
				}
			else
				ar.result(nil)
			end
		}
		ar
	end


	def rpc_getd_data(okey)
		ar = MessagePack::RPC::AsyncResult.new
		DataClientBus.get(okey, true) {|data,error|
			if error
				$log.warn("failed to get data from DS: okey=#{okey}: #{error} rsid=#{okey.rsid}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				#data ||= ""
				ar.result(data)
			end
		}
		ar
	end

	def rpc_readd(okey, offset, size)
		ar = MessagePack::RPC::AsyncResult.new
		DataClientBus.read(okey, offset, size, true) {|data,error|
			if error
				$log.warn("failed to get data from DS: okey=#{okey}: #{error} rsid=#{okey.rsid}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				#data ||= ""
				ar.result(data)
			end
		}
		ar
	end


	def rpc_add(key, data, attrs)
		rpc_add_impl(nil, key, data, attrs)
	end

	def rpc_add_data(key, data)
		rpc_add_impl(nil, key, data, {})
	end


	def rpc_addv(vname, key, data, attrs)
		rpc_add_impl(vname, key, data, attrs)
	end

	def rpc_addv_data(vname, key, data)
		rpc_add_impl(vname, key, data, {})
	end


	def rpc_add_impl(vname, key, data, attrs)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.add(key, attrs, vname) {|okey,error|
			if error
				$log.warn("failed to set a key or attributes to MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				DataClientBus.set(okey, data) {|_,error|
					if error
						ar.error(error.to_s)
					else
						ar.result(okey)
					end
				}
			end
		}
		ar
	end


	def rpc_update_attrs(key, attrs)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.update_attrs(key, attrs) {|okey,error|
			if error
				$log.warn("failed to set a key or attributes to MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				ar.result(okey)
			end
		}
		ar
	end


	def rpc_remove(key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.remove(key) {|okey,error|
			if error
				$log.warn("failed remove a key from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				ar.result(true)
			else
				ar.result(false)
			end
		}
		ar
	end


	def rpc_delete(key)
		rpc_delete_impl(nil, key)
	end

	def rpc_deletet(vtime, key)
		rpc_delete_impl(vtime, key)
	end

	def rpc_deletev(vname, key)
		rpc_delete_impl(vname, key)
	end

	def rpc_delete_impl(version, key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.delete(key, version) {|okey,error|
			if error
				$log.warn("failed delete a key from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.delete(okey) {|deleted,error|
					if error
						ar.error(error.to_s)
					else
						ar.result(deleted)
					end
				}
			else
				ar.result(false)
			end
		}
		ar
	end


	def rpc_url(key)
		rpc_url_impl(nil, key)
	end

	def rpc_urlt(vtime, key)
		rpc_urlt_impl(vtime, key)
	end

	def rpc_urlv(vname, key)
		rpc_urlv_impl(vname, key)
	end

	def rpc_url_impl(version, key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.get_okey(key, version) {|okey,error|
			if error
				$log.warn("failed to get a key or attributes from MDS: key=#{key.inspect}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.url(okey, true) {|url,error|
					if error
						$log.warn(error)
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					ar.result(url)
				}
			else
				ar.result(nil)
			end
		}
		ar
	end

	def rpc_util_locate(key)
		ar = MessagePack::RPC::AsyncResult.new
		CachedMDSBus.util_locate(key) {|array,error|
			if error
				$log.warn(error)
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				ar.result(array)
			end
		}
		ar
	end

	ebus_connect :GWRPCBus,
		:get          => :rpc_get,
		:get_data     => :rpc_get_data,
		:get_attrs    => :rpc_get_attrs,
		:read         => :rpc_read,
		:gett         => :rpc_gett,
		:gett_data    => :rpc_gett_data,
		:gett_attrs   => :rpc_gett_attrs,
		:readt        => :rpc_readt,
		:getv         => :rpc_getv,
		:getv_data    => :rpc_getv_data,
		:getv_attrs   => :rpc_getv_attrs,
		:readv        => :rpc_readv,
		:getd_data    => :rpc_getd_data,
		:readd        => :rpc_readd,
		:add          => :rpc_add,
		:add_data     => :rpc_add_data,
		:addv         => :rpc_addv,
		:addv_data    => :rpc_addv_data,
		:update_attrs => :rpc_update_attrs,
		:remove       => :rpc_remove,
		:delete       => :rpc_delete,
		:deletet      => :rpc_deletet,
		:deletev      => :rpc_deletev,
		:url          => :rpc_url,
		:urlt         => :rpc_urlt,
		:urlv         => :rpc_urlv,
		:util_locate  => :rpc_util_locate
end


end
