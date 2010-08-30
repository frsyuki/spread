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


class BootInfo
	def initialize
		@confsvr = nil
		@name = nil
		@address = nil
		@nid = nil
		@roles = nil
		@role_data = {}
	end

	attr_reader :confsvr
	attr_reader :role_data

	def node
		Node.new(@nid, @address, @name, @roles)
	end

	def read(path)
		raw = File.read(path)
		yaml = YAML.load(raw)

		confsvr = yaml['confsvr']
		raise "confsvr field is requred" unless confsvr

		host, port = confsvr.split(':',2)
		@confsvr = Address.new(host, port)

		name = yaml['name']
		raise "name field is requred" unless name
		@name = name

		address = yaml['address']
		raise "address field is requred" unless name
		host, port = address.split(':',2)
		@address = Address.new(host, port)

		nid = yaml['nid']
		raise "nid field is require" unless nid
		@nid = nid

		role = yaml['role']
		raise "role field is require" unless role
		if role.is_a?(Array)
			@roles = role
		else
			@roles = [role]
		end

		@role_data = {}
		@roles.each {|role|
			if data = yaml[role]
				@role_data[role] = data
			end
		}

		@path = path

		self
	end

	def write(path = @path)
		yaml = {
			'confsvr' => @confsvr.to_s,
			'name'    => @name,
			'address' => @address.to_s,
			'nid'     => @nid,
			'role'    => @roles,
		}
		yaml.merge!(@role_data)

		raw = YAML.dump(yaml)
		File.open(path, 'w') {|f| f.write raw }

		self
	end
end


end

