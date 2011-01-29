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


SYNC_MEMBERSHIP     = 0
SYNC_FAULT_LIST     = 1
SYNC_REPLSET_WEIGHT = 2
SYNC_MDS_URI        = 3


class SyncBus < Bus
	call_slot :get_hash

	call_slot :check_hash
	call_slot :update

	call_slot :register_callback
	call_slot :try_sync
end


class SyncService < Service
	def initialize
		@hash_array = []
		update_hash
	end

	def get_hash
		@hash
	end

	ebus_connect :SyncBus,
		:get_hash

	private
	def update_hash
		@hash = Digest::SHA1.digest(@hash_array.to_msgpack)
	end
end


class SyncServerService < SyncService
	def initialize
		@data_array = []
		super
	end

	def check_hash(hash)
		@hash == hash
	end

	def update(id, data, hash)
		@data_array[id] = data
		@hash_array[id] = hash
		update_hash
		nil
	end

	def rpc_sync_config(hash_array)
		result = []

		hash_array.each_with_index {|hash,id|
			if h = @hash_array[id]
				if h != hash
					result[id] = @data_array[id]
				end
			end
		}

		result
	end

	ebus_connect :SyncBus,
		:update,
		:check_hash

	ebus_connect :CSRPCBus,
		:sync_config => :rpc_sync_config
end


class SyncClientService < SyncService
	def initialize
		@callback_array = []
		super
	end

	def register_callback(id, initial_hash, &block)
		@callback_array[id] = block
		@hash_array[id] = initial_hash
		update_hash
		nil
	end

	def try_sync
		do_sync
		nil
	end

	def sync_blocking!
		do_sync.join
	end

	ebus_connect :SyncBus,
		:register_callback,
		:try_sync

	private
	def do_sync
		get_cs_session.callback(:sync_config, @hash_array) do |future|
			begin
				data_array = future.get
				ack_sync(data_array)
			rescue
				$log.error "sync error: #{$!}"
				$log.error $!.backtrace.pretty_inspect
			end
		end
	end

	def ack_sync(data_array)
		data_array.each_with_index {|obj,id|
			if obj
				if callback = @callback_array[id]
					$log.debug "sync: #{id} => #{obj.inspect}"
					@hash_array[id] = callback.call(obj)
				end
			end
		}
		update_hash
	end

	def get_cs_session
		ProcessBus.get_session(ConfigBus.get_cs_address)
	end
end


end
