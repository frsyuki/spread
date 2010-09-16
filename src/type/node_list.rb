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


class NodeList
	def initialize
		@nodes = []
		@path = nil
		update_hash
	end

	attr_reader :nodes

	def read(path)
		unless File.exist?(path)
			@nodes = []
			@path = path
			return update_hash
		end

		raw = File.read(path)
		yaml = YAML.load(raw)

		@nodes = yaml.map {|n|
			#name = n['name']
			#raise "name field is requred" unless name

			#address = n['address']
			#raise "address field is requred" unless name
			#host, port = address.split(':',2)
			#address = Address.new(host, port)

			#nid = n['nid']
			#raise "nid field is require" unless nid

			#role = n['role']
			#raise "role field is require" unless role

			#data = n['data']
			#raise "data field is require" unless data

			#role_data = RoleData.data_from_msgpack(role, data)

			#Node.new(nid, address, name, role_data)
			Node.new.from_msgpack(n)
		}

		@path = path

		update_hash
	end

	def write(path = @path)
		return nil unless path

		yaml = @nodes.map {|node|
			MessagePack.unpack(node.to_msgpack)
			#{
			#	'name'      => node.name,
			#	'address'   => node.address.to_s,
			#	'nid'       => node.nid,
			#	'role'      => node.role,
			#	'role_data' => node.role_data,
			#}
		}

		raw = YAML.dump(yaml)
		File.open(path, 'w') {|f| f.write raw }

		true
	end

	def add(node)
		if @nodes.include?(node)
			return nil
		end
		@nodes.push(node)
		update_hash
		true
	end

	def include?(nid)
		@nodes.each {|node|
			if node.nid == nid
				return true
			end
		}
		return false
	end

	def remove(nid)
		unless @nodes.reject! {|node| node.nid == nid }
			return nil
		end
		update_hash
		true
	end

	def get_nids
		@nodes.map {|node| node.nid }
	end

	def get_role_nodes(role)
		@nodes.select {|node| node.role == role }
	end

	def get_hash
		@hash
	end

	def to_s
		"NodeInfo #{@nodes.size} nodes [\n" +
			@nodes.map{|n| "  #{n}\n" }.join +
			"  ] hash=#{@hash.to_s.unpack('C*').map{|c|"%0x"%c}.join}"
	end

	private
	def update_hash
		@hash = Digest::SHA1.digest(to_msgpack)
		nil
	end

	public
	def to_msgpack(out = '')
		@nodes.to_msgpack(out)
	end
	def from_msgpack(obj)
		@nodes = obj.map {|o| Node.new.from_msgpack(o) }
		update_hash
		self
	end
end


end

