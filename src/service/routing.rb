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


class RoutingService < Service
	def initialize
		super()
		@replset_info = ReplsetInfo.new
	end

	attr_reader :replset_info

	def get_replset_nids(rsid)
		info = @replset_info[rsid]
		unless info
			raise "Unknown replset id: #{rsid}"
		end
		info.nids
	end

	def node_list_changed(node_list)
		map = {}  # {rsid => [nids]}
		node_list.get_role_nodes("ds").each {|node|
			ds_role_data = node.role_data
			rsid = ds_role_data.rsid
			nids = map[rsid] ||= []
			nids << node.nid
		}
		if @replset_info.rebuild(map)
			ebus_signal :replset_info_changed, @replset_info
		end
		$log.trace @replset_info.inspect
	end

	# TODO
	def choice_next_replset(key)
		rsids = @replset_info.get_rsids
		rsids.shuffle.first
	end

	ebus_connect :get_replset_nids
	ebus_connect :choice_next_replset
	ebus_connect :rpc_get_replset_info, :replset_info
	ebus_connect :node_list_changed
end


end

