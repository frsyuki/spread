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


class DSBootService < Service
	def initialize
		super()
		init_service
	end

	def init_service
		LocatorService.init
		TermEaterService.init
		RoutingService.init
		StorageIndexService.init
		MasterStorageService.init
		SlaveStorageService.init
		HeartbeatClientService.init
		TimerService.init
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


class DSConfigService < Service
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

		confsvr = yaml['confsvr']
		raise "confsvr field is requred" unless confsvr

		host, port = confsvr.split(':',2)
		@confsvr = Address.new(host, port)

		replset = yaml['replset']
		raise "replset field is require" unless replset
		raise "replset must be > 0" unless replset.to_i > 0
		@replset = replset.to_i

		storage_path = yaml["storage_path"]
		raise "storage_path field is required on osd role" unless storage_path
		@storage_path = storage_path

		@self_node = Node.new(@nid, @address, @name, DSRoleData.new(@replset))

		@path = path
	end

	def write(path = @path)
		yaml = {
			'confsvr'    => @confsvr.to_s,
			'name'       => @name,
			'address'    => @address.to_s,
			'nid'        => @nid,
			'replset'    => @replset,
			'storage_path' => @storage_path,
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

	attr_reader :confsvr
	attr_reader :replset
	attr_reader :storage_path

	ebus_connect :self_node
	ebus_connect :self_name, :name
	ebus_connect :self_address, :address
	ebus_connect :self_nid, :nid

	ebus_connect :get_confsvr_address, :confsvr
	ebus_connect :get_storage_path, :storage_path
end


end

