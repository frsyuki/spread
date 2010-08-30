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


# QS
# DSはLocatorService
class NodesInfoService < Service
	def initialize
		super()

		nodes_path = ebus_call(:get_nodes_path)
		@nodes_info = NodesInfo.new
		@nodes_info.read(nodes_path)

		@nodes_info.nodes.each {|node|
			$log.trace "node: #{node}"
		}
	end

	attr_reader :nodes_info

	def add_node(nid)
		node = ebus_call(:recognized_node, nid)
		unless node
			raise "nid #{nid} is not recognized"
		end
		if @nodes_info.add(node)
			ebus_signal :nodes_info_changed, @nodes_info
			@nodes_info.write
			return true
		end
		nil
	end

	def remove_node(nid)
		if @nodes_info.remove(nid)
			ebus_signal :nodes_info_changed, @nodes_info
			@nodes_info.write
			return true
		end
		nil
	end

	def rpc_get_nodes_info
		@nodes_info
	end

	ebus_connect :get_nodes_info, :nodes_info
	ebus_connect :rpc_add_node, :add_node
	ebus_connect :rpc_remove_node, :remove_node
	ebus_connect :rpc_get_nodes_info
end


end

