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


class MDSRoleService < Service
	def initialize
		super()
		role_config
		LocatorService.init
		NodesInfoService.init
		FaultInfoService.init
		ReplsetInfoService.init
		RecognizeService.init
		SeqidGeneratorService.init
		ObjectIndexService.init
	end

	def role_config
		role_data = ebus_call(:role_data)
		data = role_data['mds'] || {}

		@nodes_path = data["nodes_path"]
		raise "nodes_path field is required on osd role" unless @nodes_path

		@replset_path = data["replset_path"]
		raise "replset_path field is required on osd role" unless @replset_path

		@seqid_path = data["seqid_path"]
		raise "seqid_path field is required on osd role" unless @seqid_path

		@index_path = data["index_path"]
		raise "index_path field is required on osd role" unless @index_path
	end

	attr_reader :nodes_path
	attr_reader :replset_path
	attr_reader :seqid_path
	attr_reader :index_path

	def run
		nodes_info = ebus_call(:get_nodes_info)
		nodes_info.add(ebus_call(:self_node))
		ebus_signal :nodes_info_changed, nodes_info

		replset_info = ebus_call(:get_replset_info)
		ebus_signal :replset_info_changed, replset_info
	end

	def shutdown
	end

	ebus_connect :get_nodes_path, :nodes_path
	ebus_connect :get_replset_path, :replset_path
	ebus_connect :get_seqid_path, :seqid_path
	ebus_connect :get_index_path, :index_path

	ebus_connect :run
	ebus_connect :shutdown
end


end

