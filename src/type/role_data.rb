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


class RoleData
	def self.data_from_msgpack(role, obj)
		case role
		when DSRoleData::ID
			return DSRoleData.new.from_msgpack(obj)
		when MDSRoleData::ID
			return MDSRoleData.new.from_msgpack(obj)
		else
			# FIXME
			raise "unknown role"
		end
	end
end


class DSRoleData < RoleData
	ID = "ds"

	def initialize(rsid=nil)
		@rsid = rsid
	end

	attr_reader :rsid

	public
	def to_msgpack(out = '')
		[@rsid].to_msgpack(out)
	end
	def from_msgpack(obj)
		@rsid = obj[0]
		self
	end
end


class MDSRoleData < RoleData
	ID = "mds"

	def initialize(qsid=nil)
		@qsid = qsid
	end

	attr_reader :qsid

	public
	def to_msgpack(out = '')
		[@qsid].to_msgpack(out)
	end
	def from_msgpack(obj)
		@qsid = obj[0]
		self
	end
end


end

