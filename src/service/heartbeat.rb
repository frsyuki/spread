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


class HeartbeatServerService < Service
	def initialize
		super()
	end

	def rpc_heartbeat(hbreq)
		hbres = HeartbeatResponse.new

		nodes_info = ebus_call(:get_nodes_info)
		if hbreq.nodes_info_hash != nodes_info.get_hash
			hbres.nodes_info = nodes_info
		end

		fault_info = ebus_call(:get_fault_info)
		if hbreq.fault_info_hash != fault_info.get_hash
			hbres.fault_info = fault_info
		end

		replset_info = ebus_call(:get_replset_info)
		if hbreq.replset_info_hash != replset_info.get_hash
			hbres.replset_info = replset_info
		end

		if hbreq.nid
			hbres.term = ebus_call(:term_order, hbreq.nid)
		end

		hbres
	end

	ebus_connect :rpc_heartbeat
end


class HeartbeatClientService < Service
	def initialize
		super()
		@self_nid = ebus_call(:self_nid)
		@confsvr = ebus_call(:confsvr_address)
		@nodes_info_hash = 0
		@fault_info_hash = 0
		@replset_info_hash = 0
	end

	def on_timer
		hbreq = HeartbeatRequest.new
		hbreq.nid = @self_nid
		hbreq.nodes_info_hash = @nodes_info_hash
		hbreq.fault_info_hash = @fault_info_hash
		hbreq.replset_info_hash = @replset_info_hash

		s = $net.get_session(@confsvr)
		s.callback(:heartbeat, hbreq) do |future|
			heartbeat_ack(future)
		end
	end

	def heartbeat_ack(future)
		hbres = HeartbeatResponse.new.from_msgpack(future.get)

		if hbres.nodes_info
			ebus_signal(:nodes_info_changed, hbres.nodes_info)
			@nodes_info_hash = hbres.nodes_info.get_hash
		end

		if hbres.fault_info
			ebus_signal(:fault_info_changed, hbres.fault_info)
			@fault_info_hash = hbres.fault_info.get_hash
		end

		if hbres.replset_info
			ebus_signal(:replset_info_changed, hbres.replset_info)
			@replset_info_hash = hbres.replset_info.get_hash
		end

		if hbres.term
			# FIXME qsid
			ebus_call(:term_feed, 0, hbres.term)
		else
			# FIXME
			s = $net.get_session(@confsvr)
			self_node = ebus_call(:self_node)
			s.notify(:register, self_node)
		end
	end

	ebus_connect :timer_clock, :on_timer
end


class HeartbeatLeanerService < Service
	def initialize
		super()
		@confsvr = ebus_call(:confsvr_address)
		@nodes_info_hash = 0
		@fault_info_hash = 0
		@replset_info_hash = 0
	end

	def on_timer
		hbreq = HeartbeatRequest.new
		hbreq.nid = nil
		hbreq.nodes_info_hash = @nodes_info_hash
		hbreq.fault_info_hash = @fault_info_hash
		hbreq.replset_info_hash = @replset_info_hash

		s = $net.get_session(@confsvr)
		s.callback(:heartbeat, hbreq) do |future|
			heartbeat_ack(future)
		end
	end

	def heartbeat_ack(future)
		hbres = HeartbeatResponse.new.from_msgpack(future.get)

		if hbres.nodes_info
			ebus_signal(:nodes_info_changed, hbres.nodes_info)
			@nodes_info_hash = hbres.nodes_info.get_hash
		end

		if hbres.fault_info
			ebus_signal(:fault_info_changed, hbres.fault_info)
			@fault_info_hash = hbres.fault_info.get_hash
		end

		if hbres.replset_info
			ebus_signal(:replset_info_changed, hbres.replset_info)
			# FIXME qsid
			@replset_info_hash = hbres.replset_info.get_hash
		end
	end

	ebus_connect :timer_clock, :on_timer
end


end

