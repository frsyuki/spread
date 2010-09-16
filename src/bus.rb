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
	# MembershipService
	signal_slot :node_fault_detected
	call_slot :get_node_list
	call_slot :get_fault_info
	call_slot :rpc_attach_node
	call_slot :rpc_detach_node
	call_slot :rpc_recover_node
	call_slot :rpc_get_node_list
	call_slot :rpc_get_fault_info
	call_slot :rpc_get_new_nodes
	call_slot :rpc_add_new_node

	# HeartbeatServerService
	call_slot :rpc_heartbeat

	# XConfigService
	call_slot :self_node
	call_slot :self_name
	call_slot :self_address
	call_slot :self_nid

	# DSConfigService
	call_slot :get_confsvr_address
	call_slot :get_storage_path

	# MDSConfigService
	call_slot :get_nodes_path
	call_slot :get_replset_path
	call_slot :get_seqid_path
	call_slot :get_mds_db_path

	# GWConfigService
	call_slot :get_listen_address

	# TermFeederService
	signal_slot :term_nids_changed
	call_slot :term_order
	call_slot :term_reset

	# TermEaterService
	call_slot :term_feed

	# LocatorService
	call_slot :get_node

	# MetadataService
	call_slot :rpc_add_key
	call_slot :rpc_get_key
	call_slot :rpc_get_child_keys
	call_slot :rpc_set_attributes
	call_slot :rpc_remove_key

	# MasterStorageService
	call_slot :rpc_add_object_direct
	call_slot :rpc_replicate_pull

	# SlaveStorageService
	call_slot :rpc_replicate_request

	# StorageIndexService
	call_slot :get_storage_index
	call_slot :register_storage
	call_slot :rpc_get_object_direct

	# RoutingService
	call_slot :get_replset_nids
	call_slot :choice_next_replset
	call_slot :rpc_get_replset_info

	# MetadataClientService
	call_slot :metadata_get_key
	call_slot :metadata_add_key
	call_slot :metadata_get_child_keys
	call_slot :metadata_set_attributes
	call_slot :metadata_remove_key

	# GatewayService
	call_slot :rpc_get_object
	call_slot :rpc_add_object
	call_slot :rpc_set_object_attributes
	call_slot :rpc_get_object_attributes

	# OIDGeneratorService
	call_slot :generate_next_oid

	# global signals
	signal_slot :run
	signal_slot :shutdown
	signal_slot :on_timer
	signal_slot :node_list_changed
	signal_slot :fault_info_changed
	signal_slot :replset_info_changed

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

