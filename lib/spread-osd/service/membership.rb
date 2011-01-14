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


class MembershipBus < Bus
	call_slot :get_session_nid
	call_slot :get_node
	call_slot :get_replset_nids
	call_slot :is_fault

	call_slot :reset_fault_detector

	call_slot :select_next_rsid

	call_slot :try_register_node
end


class MembershipService < Service
	def initialize
		@membership = Membership.new
		@fault_list = FaultList.new
	end

	def run
		@fault_path = ConfigBus.get_fault_path
		@membership_path = ConfigBus.get_membership_path
		@fault_list.open(@fault_path) if @fault_path
		@membership.open(@membership_path) if @membership_path
	end

	def shutdown
		@fault_list.close if @fault_path
		@membership.close if @membership_path
	end

	def get_node(nid)
		@membership.get_node(nid)
	end

	def get_replset_nids(rsid)
		@membership.get_replset_nids(rsid)
	end

	def is_fault(nid)
		@fault_list.include?(nid)
	end

	def get_session_nid(nid)
		ProcessBus.get_session(get_node(nid).address)
	end

	def stat_membership_info
		@membership
	end

	def stat_replest_info
		result = {}
		@membership.get_all_rsids.each {|rsid|
			begin
				nids = @membership.get_replset_nids(rsid)
				w = @weight.get_weight(rsid)
				result[rsid] = [nids, w]
			rescue
			end
		}
		result
	end

	def stat_fault_info
		@fault_list
	end

	ebus_connect :ProcessBus,
		:run,
		:shutdown

	ebus_connect :MembershipBus,
		:get_node,
		:get_replset_nids,
		:is_fault,
		:get_session_nid

	ebus_connect :StatBus,
		:membership_info => :stat_membership_info,
		:replset_info => :stat_replest_info,
		:fault_info => :stat_fault_info
end


class MembershipManagerService < MembershipService
	def initialize
		super
		@fault_detector = FaultDetector.new
		@weight = WeightInfo.new
	end

	def run
		super
		@fault_detector.set_init(
			@membership.get_all_nids,
			@fault_list.get_list)
		update_membership
		update_fault_list
	end

	def rpc_add_node(nid, address, name, rsids)
		if @membership.include?(nid)
			if @membership.update_node_info(nid, address, name, rsids)
				$log.info "update node: nid=#{nid} name=#{name.dump} address=#{address} rsids=#{rsids.join(',')}"
			end
		else
			@membership.add_node(nid, address, name, rsids)
			$log.info "add node: nid=#{nid} name=#{name.dump} address=#{address} rsids=#{rsids.join(',')}"
		end
		@fault_detector.set_nid(nid)
		update_membership
		update_fault_list
		true
	end

	def rpc_remove_node(nid)
		$log.info "remove node: nid=#{nid}"
		@membership.remove_node(nid)
		@fault_detector.delete_nid(nid)
		update_membership
		update_fault_list
		true
	end

	def rpc_update_node_info(nid, address, name, rsids)
		@membership.update_node_info(nid, address, name, rsids)
		update_membership
		true
	end

	def rpc_recover_node(nid)
		if @fault_detector.reset(nid)
			update_fault_list
			true
		else
			nil
		end
	end

	def rpc_set_replset_weight(rsid, weight)
		unless @weight.set_weight(rsid, weight)
			raise "no such rsid: #{rsid}"
		end
		update_weight
		true
	end

	def reset_fault_detector(nid)
		term = @fault_detector.update(nid)
		term
	end

	def on_timer
		fault_nids = @fault_detector.forward_timer
		if !fault_nids.empty?
			$log.info "fault detected: #{fault_nids.join(', ')}"
			update_fault_list
		end
	end

	ebus_connect :ProcessBus,
		:run,
		:on_timer

	ebus_connect :MembershipBus,
		:reset_fault_detector

	ebus_connect :CSRPCBus,
		:add_node => :rpc_add_node,
		:remove_node => :rpc_remove_node,
		:update_node_info => :rpc_update_node_info,
		:recover_node => :rpc_recover_node,
		:set_replset_weight => :rpc_set_replset_weight

	private
	def update_membership
		@weight.set_default(@membership.get_all_rsids)
		HeartbeatBus.update_sync_config(CONFIG_SYNC_MEMBERSHIP,
							@membership, @membership.get_hash)
		update_weight
	end

	def update_weight
		HeartbeatBus.update_sync_config(CONFIG_SYNC_REPLSET_WEIGHT,
							@weight, @weight.get_hash)
	end

	def update_fault_list
		@fault_list.update(@fault_detector.get_fault_nids)
		HeartbeatBus.update_sync_config(CONFIG_SYNC_FAULT_LIST,
							@fault_list, @fault_list.get_hash)
	end
end


class MembershipClientService < MembershipService
	def initialize
		super
		@weight = WeightBalancer.new
	end

	def select_next_rsid
		@weight.select_next_rsid
	end

	def run
		super

		@weight.set_rsids(@membership.get_all_rsids)

		HeartbeatBus.register_sync_config(CONFIG_SYNC_MEMBERSHIP,
							@membership.get_hash) do |obj|
			@membership.from_msgpack(obj)
			@weight.set_rsids(@membership.get_all_rsids)
			@membership.get_hash
		end

		HeartbeatBus.register_sync_config(CONFIG_SYNC_FAULT_LIST,
							@fault_list.get_hash) do |obj|
			@fault_list.from_msgpack(obj)
			@fault_list.get_hash
		end

		HeartbeatBus.register_sync_config(CONFIG_SYNC_REPLSET_WEIGHT,
							@weight.get_hash) do |obj|
			@weight.from_msgpack(obj)
			@weight.get_hash
		end
	end

	ebus_connect :MembershipBus,
		:select_next_rsid
end


class MembershipMemberService < MembershipClientService
	def initialize
		super
		@self_nid = ConfigBus.self_nid
		@self_address = ConfigBus.self_address
		@self_name = ConfigBus.self_name
		@self_rsids = ConfigBus.self_rsids
	end

	def run
		super

		HeartbeatBus.register_sync_config(CONFIG_SYNC_MEMBERSHIP,
							@membership.get_hash) do |obj|
			@membership.from_msgpack(obj)
			try_register_node
			@membership.get_hash
		end

		HeartbeatBus.register_sync_config(CONFIG_SYNC_FAULT_LIST,
							@fault_list.get_hash) do |obj|
			@fault_list.from_msgpack(obj)
			try_register_node
			@fault_list.get_hash
		end
	end

	def try_register_node
		begin
			node = @membership.get_node(@self_nid)
		rescue
			return register_self
		end

		if node.address != @self_address
			return register_self
		end

		if node.name != @self_name
			return register_self
		end

		if node.rsids != @self_rsids
			return register_self
		end

		if @fault_list.include?(@self_nid)
			return register_self
		end

		nil
	end

	def register_self_blocking!
		do_register_self.join
	end

	ebus_connect :MembershipBus,
		:try_register_node

	private
	def get_cs_session
		ProcessBus.get_session(ConfigBus.get_cs_address)
	end

	def do_register_self
		get_cs_session.callback(:add_node, @self_nid, @self_address, @self_name, @self_rsids) do |future|
			ack_register_self(future)
		end
	end

	def register_self
		do_register_self
		true
	end

	def ack_register_self(future)
		future.get
	rescue
		$log.error "add_node error: #{future.error}"
	end
end


end
