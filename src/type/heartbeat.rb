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


class HeartbeatRequest
	# config_hash
	def initialize(nid=nil, node_list_hash=0, fault_info_hash=0)
		@nid = nid
		@node_list_hash = node_list_hash
		@fault_info_hash = fault_info_hash
	end

	attr_accessor :nid
	attr_accessor :node_list_hash
	attr_accessor :fault_info_hash

	public
	def to_msgpack(out = '')
		[@nid, @node_list_hash, @fault_info_hash].to_msgpack(out)
	end
	def from_msgpack(obj)
		@nid = obj[0]
		@node_list_hash = obj[1]
		@fault_info_hash = obj[2]
		self
	end
end


class HeartbeatResponse
	def initialize(term=nil, node_list=nil, fault_info=nil)
		@term = term
		@node_list = node_list
		@fault_info = fault_info
	end

	attr_accessor :term
	attr_accessor :node_list
	attr_accessor :fault_info

	public
	def to_msgpack(out = '')
		[@term, @node_list, @fault_info].to_msgpack(out)
	end
	def from_msgpack(obj)
		@term = obj[0]
		if node_list = obj[1]
			@node_list = NodeList.new.from_msgpack(node_list)
		end
		if fault_info = obj[2]
			@fault_info = FaultInfo.new.from_msgpack(fault_info)
		end
		self
	end
end


end

