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


class MDSBootService < Service
	def initialize
		super()
		init_service
	end

	def init_service
		LocatorService.init
		TermFeederService.init
		MembershipService.init
		RoutingService.init
		OIDGeneratorService.init
		MetadataService.init
		HeartbeatServerService.init
		TimerService.init
		MembershipService.instance.init_signal
	end

	def run
		rpc = RPCDispatcher.new

		$net.serve(rpc)

		addr = ebus_call(:self_address)
		port = addr.port
		$net.listen('0.0.0.0', port)

		puts "run on #{port}"
	end

	ebus_connect :run
end


class MDSConfigService < Service
	def initialize
		super()
	end

	def read(path)
		raw = File.read(path)
		yaml = YAML.load(raw)

		name = yaml['name']
		raise "name field is requred" unless name
		@name = name

		address = yaml['address']
		raise "address field is requred" unless name
		host, port = address.split(':',2)
		@address = Address.new(host, port)

		nid = yaml['nid']
		raise "nid field is require" unless nid
		raise "nid must be > 0" unless nid.to_i > 0
		@nid = nid.to_i

		@nodes_path = yaml["nodes_path"]
		raise "nodes_path field is required on osd role" unless @nodes_path

		@replset_path = yaml["replset_path"]
		raise "replset_path field is required on osd role" unless @replset_path

		@mds_db_path = yaml["mds_db_path"]
		raise "mds_db_path field is required on osd role" unless @mds_db_path

		@seqid_path = yaml["seqid_path"]
		raise "seqid_path field is required on osd role" unless @seqid_path

		@self_node = Node.new(@nid, @address, @name, MDSRoleData.new(0))

		@path = path
	end

	def write(path = @path)
		yaml = {
			'name'         => @name,
			'address'      => @address.to_s,
			'nid'          => @nid,
			'nodes_path'   => @nodes_path,
			'replset_path' => @replset_path,
			'mds_db_path'  => @mds_db_path,
			'seqid_path'   => @seqid_path,
		}
		yaml.merge!(@role_data)

		raw = YAML.dump(yaml)
		File.open(path, 'w') {|f| f.write raw }

		self
	end

	attr_reader :self_node
	attr_reader :name
	attr_reader :address
	attr_reader :nid

	attr_reader :nodes_path
	attr_reader :replset_path
	attr_reader :mds_db_path
	attr_reader :seqid_path

	ebus_connect :self_node
	ebus_connect :self_name, :name
	ebus_connect :self_address, :address
	ebus_connect :self_nid, :nid

	ebus_connect :get_nodes_path, :nodes_path
	ebus_connect :get_replset_path, :replset_path
	ebus_connect :get_mds_db_path, :mds_db_path
	ebus_connect :get_seqid_path, :seqid_path
end


end

