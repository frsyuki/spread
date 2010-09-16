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


class LocatorService < Service
	def initialize
		super()
		@nodes_map = {}   # {nid => node}
	end

	# アクティブなノードのみ含む
	def get_node(nid)
		unless @nodes_map.include?(nid)
			raise "Unknown node id: #{nid}"
		end
		@nodes_map[nid]
	end

	def node_list_changed(node_list)
		nodes_map = {}
		node_list.nodes.each {|node|
			nodes_map[node.nid] = node
			$log.trace "node: #{node}"
		}
		@nodes_map = nodes_map
	end

	ebus_connect :node_list_changed
	ebus_connect :get_node
end


end

