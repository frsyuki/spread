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
require 'lib/ebus'

module SpreadOSD


class EBus < EventBus::Static
	# NodesInfoService
	call_slot :get_nodes_info
	call_slot :rpc_add_node
	call_slot :rpc_remove_node
	call_slot :rpc_get_nodes_info

	# FaultInfoService
	call_slot :get_fault_info
	call_slot :rpc_recover_fault
	call_slot :rpc_get_fault_info

	# HeartbeatServerService
	call_slot :rpc_heartbeat

	# BootInfoService
	signal_slot :boot_info_loaded
	call_slot :self_node
	call_slot :self_address
	call_slot :self_nid
	call_slot :self_name
	call_slot :role_data
	call_slot :confsvr_address

	# OSDRoleService
	call_slot :get_store_path

	# MDSRoleService
	call_slot :get_nodes_path
	call_slot :get_replset_path
	call_slot :get_seqid_path
	call_slot :get_index_path

	# TermFeederService
	call_slot :term_order
	call_slot :term_reset

	# TermEaterService
	call_slot :term_feed

	# TermEaterService
	signal_slot :timer_clock

	# FaultInfoService
	signal_slot :fault_nodes_detected

	# RoutingService
	call_slot :get_mds_nids
	call_slot :get_replset_nids

	# LocatorService
	call_slot :get_node

	# ObjectIndexService
	call_slot :rpc_add_key
	call_slot :rpc_get_key
	call_slot :rpc_get_child_keys
	call_slot :rpc_remove_key
	call_slot :rpc_set_attributes

	# MasterStorageService
	call_slot :get_master_storage

	# SlaveStorageService
	call_slot :get_slave_storage

	# StorageIndexService
	call_slot :get_storage_index

	# StorageService
	call_slot :rpc_get_object
	call_slot :rpc_add_object

	# ReplsetInfoService
	call_slot :get_replset_info
	call_slot :rpc_create_replset
	call_slot :rpc_join_replset
	call_slot :rpc_activate_replset
	call_slot :rpc_deactivate_replset
	call_slot :rpc_get_replset_info
	call_slot :choice_replset

	# IndexClientService
	call_slot :index_add_key
	call_slot :index_get_child_keys
	call_slot :index_get_key
	call_slot :index_remove_key

	# GatewayService
	call_slot :rpc_get
	call_slot :rpc_add

	# RecognizeService
	call_slot :rpc_register
	call_slot :rpc_recognized_nodes
	call_slot :recognized_node

	# SeqidGeneratorService
	call_slot :next_oid

	# global signals
	signal_slot :run
	signal_slot :shutdown
	signal_slot :nodes_info_changed
	signal_slot :fault_info_changed
	signal_slot :fault_detected
	signal_slot :replset_info_changed
	signal_slot :mds_changed

	def ebus_signal_error(err)
		if RUBY_VERSION >= "1.9"
			bt = 6
		else
			bt = 9
		end
		#out = ["#{err}"]
		#err.backtrace.each {|msg| out << "    #{msg}" }
		#$log.debug out.join("\n")
		$log.debug "#{err.backtrace[bt]}: #{err}"
	end
end


end

