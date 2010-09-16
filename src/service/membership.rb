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


class MembershipService < Service
	def initialize
		super()

		nodes_path = ebus_call(:get_nodes_path)
		@node_list = NodeList.new
		@node_list.read(nodes_path)
		@node_list.add(ebus_call(:self_node))

		@node_list.nodes.each {|node|
			$log.trace "node: #{node}"
		}

		@fault_info = FaultInfo.new

		@new_nodes = {}  # {nid => Node}
	end

	def node_fault_detected(nids)
		fault_info_changed = false
		new_nodes_changed = false
		nids.each {|nid|
			if @new_nodes.delete(nid)
				new_nodes_changed = true
			elsif @node_list.include?(nid)
				@fault_info.add(nid)
				fault_info_changed = true
			end
		}
		if new_nodes_changed
			signal_term_nids_changed
		end
		if fault_info_changed
			signal_fault_info_changed
			return true
		end
		nil
	end

	def detach_node(nids)
		node_list_changed = false
		new_nodes_changed = false
		nids.each {|nid|
			if @new_nodes.delete(nid)
				new_nodes_changed = true
			elsif @node_list.remove(nid)
				node_list_changed = true
			end
		}
		if new_nodes_changed || node_list_changed
			signal_term_nids_changed
		end
		if node_list_changed
			signal_node_list_changed
			return true
		end
		nil
	end

	def attach_node(nids)
		node_list_changed = false
		nids.each {|nid|
			if node = @new_nodes.delete(nid)
				@node_list.add(node)
				node_list_changed = true
			end
		}
		if node_list_changed
			signal_term_nids_changed
			signal_node_list_changed
			return true
		end
		nil
	end

	def recover_node(nids)
		fault_info_changed = false
		nids.each {|nid|
			if @fault_info.remove(nid)
				@fault_info.remove(nid)
				fault_info_changed = true
			end
		}
		if fault_info_changed
			signal_fault_info_changed
			return true
		end
		nil
	end

	def rpc_add_new_node(node)
		if @node_list.include?(node.nid)
			return nil
		end
		existing = @new_nodes.include?(node.nid)
		@new_nodes[node.nid] = node
		unless existing
			signal_term_nids_changed
		end
		true
	end

	def signal_term_nids_changed
		nids = @node_list.get_nids
		nids += @new_nodes.values.map {|node| node.nid }
		ebus_call :term_nids_changed, nids
	end

	def signal_fault_info_changed
		ebus_signal :fault_info_changed, @fault_info
	end

	def signal_node_list_changed
		@node_list.write
		ebus_signal :node_list_changed, @node_list
	end

	attr_reader :node_list
	attr_reader :fault_info

	def rpc_get_new_nodes
		@new_nodes.values
	end

	def init_signal
		signal_node_list_changed
		signal_fault_info_changed
		signal_term_nids_changed
	end

	ebus_connect :node_fault_detected
	ebus_connect :get_node_list, :node_list
	ebus_connect :get_fault_info, :fault_info

	ebus_connect :rpc_attach_node, :attach_node
	ebus_connect :rpc_detach_node, :detach_node
	ebus_connect :rpc_recover_node, :recover_node
	ebus_connect :rpc_get_node_list, :node_list
	ebus_connect :rpc_get_fault_info, :fault_info
	ebus_connect :rpc_get_new_nodes
	ebus_connect :rpc_add_new_node
end


end

