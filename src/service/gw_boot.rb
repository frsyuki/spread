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


class GWBootService < Service
	def initialize
		super()
		init_service
	end

	def init_service
		LocatorService.init
		RoutingService.init
		MetadataClientService.init
		GatewayService.init
		HeartbeatLeanerService.init
		TimerService.init
	end

	def run
		rpc = RPCDispatcher.new

		$net.serve(rpc)

		addr = ebus_call(:get_listen_address)
		host = addr.host
		port = addr.port
		$net.listen(host, port)

		puts "run on #{port}"
	end

	ebus_connect :run
end


class GWConfigService < Service
	def initialize
		super()
	end

	def read(path)
		raw = File.read(path)
		yaml = YAML.load(raw)

		confsvr = yaml['confsvr']
		raise "confsvr field is requred" unless confsvr

		host, port = confsvr.split(':',2)
		@confsvr = Address.new(host, port)

		listen = yaml['listen']
		raise "listen field is requred" unless listen

		if listen.is_a?(Integer)
			host = "0.0.0.0"
			port = listen
		else
			host, port = listen.split(':',2)
		end
		@listen = Address.new(host, port)

		@self_node = Node.new(@nid, @address, @name, DSRoleData.new(@replset))

		@path = path
	end

	def write(path = @path)
		yaml = {
			'confsvr'    => @confsvr.to_s,
			'listen'     => @listen.to_s,
		}
		yaml.merge!(@role_data)

		raw = YAML.dump(yaml)
		File.open(path, 'w') {|f| f.write raw }

		self
	end

	attr_reader :confsvr
	attr_reader :listen

	ebus_connect :get_confsvr_address, :confsvr
	ebus_connect :get_listen_address, :listen
end


end

