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


CONFIG_SYNC_MEMBERSHIP     = 0
CONFIG_SYNC_FAULT_LIST     = 1
CONFIG_SYNC_SNAPSHOT       = 2
CONFIG_SYNC_MDS_ADDRESS    = 3
CONFIG_SYNC_REPLSET_WEIGHT = 4


class HeartbeatBus < Bus
	call_slot :register_sync_config
	call_slot :update_sync_config
end


class HeartbeatResponse
	def initialize(term=nil, sync_data=[])
		@term = term
		@sync_data = sync_data
	end

	attr_accessor :term
	attr_accessor :sync_data

	public
	def to_msgpack(out = '')
		[@term, @sync_data].to_msgpack(out)
	end
	def from_msgpack(obj)
		@term = obj[0]
		if sync_data = obj[1]
			@sync_data = sync_data
		end
		self
	end
end


class HeartbeatServerService < Service
	class Entry
		def initialize(data, hash)
			@data = data
			@hash = hash
		end
		attr_reader :data
		attr_reader :hash
	end

	def initialize
		super
		@syncs = []
	end

	def update_sync_config(id, data, hash)
		@syncs[id] = Entry.new(data, hash)
		nil
	end

	def rpc_heartbeat(nid, sync_request)
		hbres = HeartbeatResponse.new

		if nid
			hbres.term = MembershipBus.reset_fault_detector(nid)
		end

		sync_request.each_with_index {|hash,id|
			if e = @syncs[id]
				if e.hash != hash
					hbres.sync_data[id] = e.data
				end
			end
		}

		hbres
	end

	ebus_connect :HeartbeatBus,
		:update_sync_config

	ebus_connect :CSRPCBus,
		:heartbeat => :rpc_heartbeat
end


class HeartbeatClientService < Service
	class Entry
		def initialize(hash, on_update)
			@hash = hash
			@on_update = on_update
		end
		attr_reader :hash
		attr_reader :on_update
	end

	def initialize
		@syncs_hash = []
		@syncs_callback = []
		@heartbeat_nid = nil
	end

	def register_sync_config(id, initial_hash, &block)
		@syncs_hash[id] = initial_hash
		@syncs_callback[id] = block
		nil
	end

	def get_cs_session
		ProcessBus.get_session(ConfigBus.get_cs_address)
	end

	def on_timer
		do_heartbeat
	end

	def do_heartbeat
		get_cs_session.callback(:heartbeat, @heartbeat_nid, @syncs_hash) do |future|
			begin
				hbres = HeartbeatResponse.new.from_msgpack(future.get)
				ack_heartbeat(hbres)
			rescue
				$log.error "heartbeat error: #{$!}"
				$log.error $!.backtrace.pretty_inspect
			end
		end
	end

	def ack_heartbeat(hbres)
		hbres.sync_data.each_with_index {|data,index|
			if data
				if callback = @syncs_callback[index]
					@syncs_hash[index] = callback.call(data)
				end
			end
		}

		# do nothing
		#if hbres.term
		#end
	end

	def heartbeat_blocking!
		do_heartbeat.join
	end

	ebus_connect :HeartbeatBus,
		:register_sync_config

	ebus_connect :ProcessBus,
		:on_timer
end


class HeartbeatMemberService < HeartbeatClientService
	def initialize
		super
		@heartbeat_nid = ConfigBus.self_nid
	end

	def ack_heartbeat(hbres)
		super

		if hbres.term
			# do nothing
		else
			# MembershipMemberService
			#register_self
		end

		MembershipBus.try_register_node
	end
end


end
