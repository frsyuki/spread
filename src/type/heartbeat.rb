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
	def initialize(nid=nil, nodes_info_hash=0, fault_info_hash=0, replset_info_hash=0)
		@nid = nid
		@nodes_info_hash = nodes_info_hash
		@fault_info_hash = fault_info_hash
		@replset_info_hash = replset_info_hash
	end

	attr_accessor :nid
	attr_accessor :nodes_info_hash
	attr_accessor :fault_info_hash
	attr_accessor :replset_info_hash

	public
	def to_msgpack(out = '')
		[@nid, @nodes_info_hash, @fault_info_hash, @replset_info_hash].to_msgpack(out)
	end
	def from_msgpack(obj)
		@nid = obj[0]
		@nodes_info_hash = obj[1]
		@fault_info_hash = obj[2]
		@replset_info_hash = obj[3]
		self
	end
end


class HeartbeatResponse
	def initialize(term=nil, nodes_info=nil, fault_info=nil, replset_info=nil)
		@term = term
		@nodes_info = nodes_info
		@fault_info = fault_info
		@replset_info = replset_info
	end

	attr_accessor :term
	attr_accessor :nodes_info
	attr_accessor :fault_info
	attr_accessor :replset_info

	public
	def to_msgpack(out = '')
		[@term, @nodes_info, @fault_info, @replset_info].to_msgpack(out)
	end
	def from_msgpack(obj)
		@term = obj[0]
		if nodes_info = obj[1]
			@nodes_info = NodesInfo.new.from_msgpack(nodes_info)
		end
		if fault_info = obj[2]
			@fault_info = FaultInfo.new.from_msgpack(fault_info)
		end
		if replset_info = obj[3]
			@replset_info = ReplsetInfo.new.from_msgpack(replset_info)
		end
		self
	end
end


end

