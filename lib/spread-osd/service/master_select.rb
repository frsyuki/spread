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


class MasterSelectBus < Bus
	call_slot :select_master
	call_slot :select_master_static
	signal_slot :update_nodes
end


class LocationAwareMasterSelectService < Service
	def initialize
		@map = {}  # { rsid => [nids] }
		@self_location = ConfigBus.self_location
	end

	def update_nodes(nodes=nil)
		nodes ||= MembershipBus.get_all_nodes

		rsid_nodes = {}
		nodes.each {|node|
			node.rsids.each {|rsid|
				(rsid_nodes[rsid] ||= []) << node
			}
		}

		rsid_loc_nids = {}
		rsid_nodes.each_pair {|rsid,nodes|
			loc_grouped = nodes.group_by {|node| node.location }

			sorted = loc_grouped.to_a.sort_by {|loc,nodes| loc }
			if idx = sorted.find_index {|loc,nodes| loc == @self_location }
				sorted = rotate(sorted, idx)
			end

			loc_nids = sorted.map {|loc,nodes|
				nids = nodes.map {|node| node.nid }
				nids.sort
			}

			rsid_loc_nids[rsid] = loc_nids
		}

		@map = rsid_loc_nids
	end

	def select_master(rsid, key)
		loc_nodes = @map[rsid]
		unless loc_nodes
			raise "no such rsid: #{rsid}"
		end
		digest = Digest::MD5.digest(key)
		i = digest.unpack('C')[0]
		loc_nodes.map {|nodes| rotate(nodes, i) }.flatten
	end

	def select_master_static(rsid)
		loc_nodes = @map[rsid]
		unless loc_nodes
			raise "no such rsid: #{rsid}"
		end
		loc_nodes.flatten
	end

	ebus_connect :MasterSelectBus,
		:select_master,
		:select_master_static,
		:update_nodes

	private
	def rotate(array, i)
		n = i % array.size
		return array[-n,n] + array[0, array.size-n]
	end
end


class FlatMasterSelectService < Service
	def initialize
		@map = {}  # { rsid => nids }
	end

	def update_nodes(nodes=nil)
		nodes ||= MembershipBus.get_all_nodes

		rsid_nids = {}
		nodes.each {|node|
			node.rsids.each {|rsid|
				(rsid_nids[rsid] ||= []) << node.nid
			}
		}

		rsid_nids.values.each {|nids|
			nids.sort!
		}

		@map = rsid_nids
	end

	def select_master(rsid, key)
		nids = @map[rsid]
		unless nids
			raise "no such rsid: #{rsid}"
		end
		digest = Digest::MD5.digest(key)
		i = digest.unpack('C')[0]
		rotate(nids, i)
	end

	def select_master_static(rsid)
		nids = @map[rsid]
		unless nids
			raise "no such rsid: #{rsid}"
		end
		nids.dup
	end

	ebus_connect :MasterSelectBus,
		:select_master,
		:select_master_static,
		:update_nodes

	private
	def rotate(array, i)
		n = i % array.size
		return array[-n,n] + array[0, array.size-n]
	end
end


end
