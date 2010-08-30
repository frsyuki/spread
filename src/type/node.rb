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


class Node
	QUORUM_SERVER = 0b0001
	SLICE_SERVER  = 0b0010
	GATEWAY       = 0b0100

	def initialize(nid=0, address=nil, name=nil, roles=[])
		@nid = nid
		@address = address
		@name = name
		@roles = roles.map {|r| r.to_sym }
	end

	attr_reader :nid
	attr_reader :address
	attr_reader :name
	attr_reader :roles

	def session
		$net.get_session(*@address)
	end

	def to_s
		"Node<#{@nid} #{@address} #{@name.dump} #{@roles.join(',')}>"
	end

	def is?(role_name)
		@roles.include?(role_name.to_sym)
	end

	public
	def to_msgpack(out = '')
		roles = @roles.map {|r| r.to_s }
		[@nid, @address.dump, @name, roles].to_msgpack(out)
	end
	def from_msgpack(obj)
		@nid = obj[0]
		@address = Address.load(obj[1])
		@name = obj[2]
		roles = obj[3]
		@roles = roles.map {|r| r.to_sym }
		self
	end
end


end

