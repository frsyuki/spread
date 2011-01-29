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


class ObjectKey
	def initialize(key=nil, vtime=nil, rsid=nil)
		@key = key
		@vtime = vtime.to_i
		@rsid = rsid.to_i
	end

	attr_reader :key
	attr_reader :vtime
	attr_reader :rsid

	def to_msgpack(out = '')
		[@key, @vtime, @rsid].to_msgpack(out)
	end

	def from_msgpack(obj)
		@key = obj[0]
		@vtime = obj[1].to_i
		@rsid = obj[2].to_i
		self
	end
end


end
