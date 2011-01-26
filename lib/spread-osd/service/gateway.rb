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
		rpc_gets(nil, key)
	end

	def rpc_get_data(key)
		rpc_gets_data(nil, key)
	end

	def rpc_get_attrs(key)
		rpc_gets_attrs(nil, key)
	end


	def rpc_gets(sid, key)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.get_okey_attrs(key, sid) {|(okey,attrs),error|
			if error
				$log.warn("failed to get a key or attributes from MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.get(okey) {|data,error|
					if error
						$log.warn(error)
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					data ||= ""
					ar.result([data,attrs], nil)
				}
			else
				ar.result([nil,nil], nil)
			end
		}
		ar
	end

	def rpc_gets_data(sid, key)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.get_okey(key, sid) {|okey,error|
			if error
				$log.warn("failed to get a key from MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.get(okey) {|data,error|
					if error
						$log.warn(error)
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					data ||= ""
					ar.result(data, nil)
				}
			else
				ar.result(nil)
			end
		}
		ar
	end

	def rpc_gets_attrs(sid, key)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.get_attrs(key, sid) {|attrs,error|
			if error
				$log.warn("failed to get attributes from MDS: key=#{key.dump}: #{error}")
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


	def rpc_read(key, offset, size)
		rpc_reads(nil, key, offset, size)
	end

	def rpc_reads(sid, key, offset, size)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.get_okey(key, sid) {|okey,error|
			if error
				$log.warn("failed to get a key from MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				DataClientBus.read(okey, offset, size) {|data,error|
					if error
						$log.warn("failed to get data from DS: key=#{key.dump}: #{error} rsid=#{okey.rsid}")
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
					end
					data ||= ""
					ar.result(data, nil)
				}
			else
				ar.result(nil)
			end
		}
		ar
	end


	def rpc_getd_data(okey)
		ar = MessagePack::RPC::AsyncResult.new
		DataClientBus.get(okey) {|data,error|
			if error
				$log.warn("failed to get data from DS: okey=#{okey}: #{error} rsid=#{okey.rsid}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				ar.result(data, nil)
			end
		}
		ar
	end

	def rpc_readd(okey, offset, size)
		ar = MessagePack::RPC::AsyncResult.new
		DataClientBus.read(okey, offset, size) {|data,error|
			if error
				$log.warn("failed to get data from DS: okey=#{okey}: #{error} rsid=#{okey.rsid}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				ar.result(data, nil)
			end
		}
		ar
	end


	def rpc_set(key, data, attrs)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.set_okey_attrs(key, attrs) {|okey,error|
			if error
				$log.warn("failed to set a key or attributes to MDS: key=#{key.dump}: #{error}")
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

	def rpc_set_data(key, data)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.set_okey(key) {|okey,error|
			if error
				$log.warn("failed to set a key to MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				DataClientBus.set(okey, data) {|_,error|
					if error
						$log.warn("failed to set a data to DS: key=#{key.dump}: #{error}")
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
						ar.error(error.to_s)
					else
						ar.result(okey)
					end
				}
			end
		}
		ar
	end

	def rpc_set_attrs(key, attrs)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.set_okey_attrs(key, attrs) {|okey,error|
			if error
				$log.warn("failed to set a key or attributes to MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				ar.result(okey)
			end
		}
		ar
	end


	def rpc_write(key, offset, data)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.set_okey(key) {|okey,error|
			if error
				$log.warn("failed to set a key to MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				DataClientBus.write(okey, offset, data) {|_,error|
					if error
						$log.warn("failed to set a data to DS: key=#{key.dump}: #{error}")
						$log.debug_backtrace error.backtrace if error.is_a?(Exception)
						ar.error(error.to_s)
					else
						ar.result(okey)
					end
				}
			end
		}
		ar
	end

	#def rpc_resize(key, size)
	#	ar = MessagePack::RPC::AsyncResult.new
	#	MDSBus.set_okey(key) {|okey,error|
	#		if error
	#			$log.warn("failed to set a data to DS: key=#{key.dump}: #{error}")
	#			$log.debug_backtrace error.backtrace if error.is_a?(Exception)
	#			ar.error(error.to_s)
	#		else
	#			DataClientBus.resize(okey, size) {|_,error|
	#				if error
	#					$log.warn("failed to resize a data on DS: key=#{key.dump} size=#{size}: #{error}")
	#					$log.debug_backtrace error.backtrace if error.is_a?(Exception)
	#					ar.error(error.to_s)
	#				else
	#					ar.result(okey)
	#				end
	#			}
	#		end
	#	}
	#	ar
	#end


	def rpc_remove(key)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.remove(key) {|okey,error|
			if error
				$log.warn("failed remove a key from MDS: key=#{key.dump}: #{error}")
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


	def rpc_select(cols, conds, order, order_col, limit, skip)
		rpc_selects(nil, cols, conds, order, order_col, limit, skip)
	end

	def rpc_selects(sid, cols, conds, order, order_col, limit, skip)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.select(cols, conds, order, order_col, limit, skip, reqdata, sid) {|array,error|
			if error
				$log.warn("failed select columns from MDS: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			else
				ar.result(array)
			end
		}
		ar
	end


	#def rpc_purge(key)
	#end

	#def rpc_purges(sid, key)
	#end


	def rpc_locate(key)
		rpc_locates(nil, key)
	end

	def rpc_locates(sid, key)
		ar = MessagePack::RPC::AsyncResult.new
		MDSBus.get_okey(key, sid) {|okey,error|
			if error
				$log.warn("failed to get a key from MDS: key=#{key.dump}: #{error}")
				$log.debug_backtrace error.backtrace if error.is_a?(Exception)
				ar.error(error.to_s)
			elsif okey
				addrs = DataClientBus.locate(okey)
				ar.result([okey, addrs])
			else
				ar.result([nil, nil])
			end
		}
		ar
	end


	ebus_connect :GWRPCBus,
		:get          => :rpc_get,
		:get_data     => :rpc_get_data,
		:get_attrs    => :rpc_get_attrs,
		:gets         => :rpc_gets,
		:gets_data    => :rpc_gets_data,
		:gets_attrs   => :rpc_gets_attrs,
		:read         => :rpc_read,
		:reads        => :rpc_reads,
		:getd_data    => :rpc_getd_data,
		:readd        => :rpc_readd,
		:set          => :rpc_set,
		:set_data     => :rpc_set_data,
		:set_attrs    => :rpc_set_attrs,
		:write        => :rpc_write,
		:remove       => :rpc_remove,
		:select       => :rpc_select,
		:selects      => :rpc_selects,
		:locate       => :rpc_locate,
		:locates      => :rpc_locates
end


end
