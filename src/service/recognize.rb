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


class RecognizeService < Service
	def initialize()
		super()
		@nodes = {}
		@known_nids = {}
	end

	def register(node)
		unless @known_nids.include?(node.nid)
			@nodes[node.nid] = node
		end
		true
	end

	def recognized_node(nid)
		@nodes[nid]
	end

	def nodes_info_changed(nodes_info)
		known_nids = []
		nodes_info.nodes.each {|node|
			known_nids[node.nid] = node.nid
		}
		@known_nids = known_nids

		@nodes.reject! {|nid,node|
			@known_nids.include?(nid)
		}
	end

	def rpc_recognized_nodes
		@nodes.values
	end

	def on_timer
	end

	ebus_connect :rpc_register, :register
	ebus_connect :recognized_node
	ebus_connect :rpc_recognized_nodes
	ebus_connect :nodes_info_changed
	ebus_connect :timer_clock, :on_timer
end


end

