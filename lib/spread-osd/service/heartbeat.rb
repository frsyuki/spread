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


class HeartbeatResponse
	def initialize(term=nil, sync_needed=nil)
		@term = term
		@sync_needed = sync_needed
	end

	attr_accessor :term
	attr_accessor :sync_needed

	public
	def to_msgpack(out = '')
		[@term, @sync_needed].to_msgpack(out)
	end
	def from_msgpack(obj)
		@term = obj[0]
		@sync_needed = obj[1]
		self
	end
end


class HeartbeatServerService < Service
	def initialize
		super
		@syncs = []
	end

	def rpc_heartbeat(nid, sync_hash)
		hbres = HeartbeatResponse.new

		if nid
			hbres.term = MembershipBus.reset_fault_detector(nid)
		end

		if sync_hash
			if SyncBus.check_hash(sync_hash)
				hbres.sync_needed = false
			else
				hbres.sync_needed = true
			end
		end

		hbres
	end

	ebus_connect :CSRPCBus,
		:heartbeat => :rpc_heartbeat
end


class HeartbeatClientService < Service
	def initialize
		@heartbeat_nid = nil
	end

	#def get_cs_session
	#	ProcessBus.get_session(ConfigBus.get_cs_address)
	#end
	#
	#def on_timer
	#	do_heartbeat
	#end
	#
	#def do_heartbeat
	#	sync_hash = SyncBus.get_hash
	#	get_cs_session.callback(:heartbeat, @heartbeat_nid, sync_hash) do |future|
	#		begin
	#			hbres = HeartbeatResponse.new.from_msgpack(future.get)
	#			ack_heartbeat(hbres)
	#		rescue
	#			$log.error "heartbeat error: #{$!}"
	#			$log.error_backtrace $!.backtrace
	#		end
	#	end
	#end
	#
	#def ack_heartbeat(hbres)
	#	if hbres.sync_needed
	#		SyncBus.try_sync
	#	end
	#end
	#
	#ebus_connect :ProcessBus,
	#	:on_timer
	#
	#def heartbeat_blocking!
	#	do_heartbeat.join
	#end

	def run
		@cs = MessagePack::RPC::Client.new(*ConfigBus.get_cs_address)
		@end = false
		@thread = Thread.new do
			while !@end
				sleep 1
				do_heartbeat_blocking
			end
		end
	end

	def shutdown
		@end = true
		#@thread.join
		@cs.close
	end

	def do_heartbeat_blocking
		sync_hash = SyncBus.get_hash
		begin
			res = @cs.call(:heartbeat, @heartbeat_nid, sync_hash)
			hbres = HeartbeatResponse.new.from_msgpack(res)
			if hbres.sync_needed
				ProcessBus.submit {
					SyncBus.try_sync
				}
			end
		rescue
			$log.error "heartbeat error: #{$!}"
			$log.error_backtrace $!.backtrace
		end
		nil
	end

	def heartbeat_blocking!
		do_heartbeat_blocking
	end

	ebus_connect :ProcessBus,
		:run,
		:shutdown
end


class HeartbeatMemberService < HeartbeatClientService
	def initialize
		super
		@heartbeat_nid = ConfigBus.self_nid
	end

	#def ack_heartbeat(hbres)
	#	super
	#
	#	if hbres.term
	#		# do nothing
	#	else
	#		# MembershipMemberService
	#		#register_self
	#	end
	#
	#	MembershipBus.try_register_node
	#end

	def on_timer
		MembershipBus.try_register_node
	end

	ebus_connect :ProcessBus,
		:on_timer
end


end
