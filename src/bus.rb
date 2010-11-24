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


class EBus < EventBus::Static
	signal_slot :run
	signal_slot :shutdown

	# NetService
	call_slot :get_session
	call_slot :start_timer

	# TimerService
	signal_slot :on_timer

	# DSConfigService
	call_slot :self_nid
	call_slot :self_name
	call_slot :self_address
	call_slot :self_rsids
	call_slot :self_node
	call_slot :get_storage_path
	call_slot :get_ulog_path
	call_slot :get_rlog_path

	# DSConfigService, GWConfigService
	call_slot :get_cs_address

	# GWConfigService
	call_slot :get_mds_addrs

	# CSConfigService, DSConfigService, GWConfigService
	call_slot :get_fault_path
	call_slot :get_membership_path
	call_slot :rpc_get_mds

	# StorageService, GatewayService
	call_slot :rpc_get
	call_slot :rpc_set
	call_slot :rpc_remove
	call_slot :rpc_get_direct
	call_slot :rpc_set_direct
	call_slot :rpc_remove_direct

	# StorageService
	call_slot :rpc_replicate_pull
	call_slot :rpc_replicate_notify
	call_slot :stat_db_items
	call_slot :stat_cmd_get
	call_slot :stat_cmd_set
	call_slot :stat_cmd_remove

	# MembershipService
	call_slot :get_session_nid
	call_slot :get_node
	call_slot :get_replset_nids
	call_slot :is_fault
	call_slot :stat_membership_info
	call_slot :stat_replest_info
	call_slot :stat_fault_info

	# MembershipManagerService
	call_slot :rpc_add_node
	call_slot :rpc_remove_node
	call_slot :rpc_update_node_info
	call_slot :rpc_recover_node
	call_slot :rpc_set_replset_weight
	call_slot :reset_fault_detector

	# MembershipClientService
	call_slot :choice_rsid

	# MembershipMemberService
	call_slot :try_register_node

	# HeartbeatServerService
	call_slot :rpc_heartbeat
	call_slot :update_config_sync

	# HeartbeatClientService
	call_slot :config_sync_register

	# MDSService
	call_slot :mds_get
	call_slot :mds_set
	call_slot :mds_remove
	#call_slot :mds_add_or_get

	# StatusService
	call_slot :rpc_status

	def ebus_signal_error(err)
		if RUBY_VERSION >= "1.9"
			bt = 6
		else
			bt = 9
		end
		out = ["#{err}"]
		err.backtrace.each {|msg| out << "    #{msg}" }
		$log.debug out.join("\n")
		#$log.debug "#{err.backtrace[bt]}: #{err}"
	end
end


end
