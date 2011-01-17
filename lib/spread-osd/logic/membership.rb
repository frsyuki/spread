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


class NodeList < TSVData
	def initialize
		@path = nil
		@map = {}  # {nid => Node}
		super()
	end

	def get(nid)
		@map[nid]
	end

	def add(node)
		@map[node.nid] = node
		on_change
		true
	end

	def delete(nid)
		if node = @map.delete(nid)
			on_change
			node
		else
			false
		end
	end

	def include?(nid)
		@map.has_key?(nid)
	end

	def update(nid, address, name, rsids)
		node = @map[nid]
		if node
			if address
				node.address = address
			end
			if name
				node.name = name
			end
			if rsids
				node.rsids = rsids
			end
			false
		else
			on_change
			true
		end
	end

	def each(&block)
		@map.each_value(&block)
	end

	def get_all_nodes
		@map.values
	end

	def get_all_nids
		@map.map {|nid,node| nid }
	end

	def to_msgpack(out = '')
		@map.values.to_msgpack(out)
	end

	def from_msgpack(obj)
		map = {}
		obj.each {|n|
			node = Node.new.from_msgpack(n)
			map[node.nid] = node
		}
		@map = map
		on_change
		self
	end

	protected
	def read
		return unless @path

		begin
			map = {}

			tsv_read do |row|
				nid = row[0].to_i

				name = row[1]

				addr = row[2].to_s
				host, port = addr.split(':',2)
				port ||= DS_DEFAULT_PORT
				address = Address.new(host, port.to_i)

				rsids = row[3].split(',').map {|id| id.to_i }

				location = row[4]

				map[nid] = Node.new(nid, address, name, rsids, location)
			end

			@map = map
		rescue
			$log.debug $!
		end

		update_hash

	rescue
		$log.debug $!
		raise
	end

	def write
		return unless @path

		tsv_write do |writer|
			@map.each_value {|node|
				row = []
				row[0] = node.nid.to_s
				row[1] = node.name
				row[2] = "#{node.address.host}:#{node.address.port}"
				row[3] = node.rsids.join(',')
				writer << row
			}
		end

	rescue
		$log.error $!
		raise
	end
end


class Membership
	def initialize
		@nodes = NodeList.new
		@active_rsids = []
	end

	def open(path)
		@nodes.open(path)
		update_active_rsids
	end

	def close
		@nodes.close
	end

	def add_node(nid, address, name, rsids, location)
		node = Node.new(nid, address, name, rsids, location)
		if @nodes.get(nid)
			raise "nid already exist: #{nid}"
		end
		@nodes.add(node)
		update_active_rsids
		node
	end

	def remove_node(nid)
		node = @nodes.delete(nid)
		unless node
			raise "nid not exist: #{nid}"
		end
		update_active_rsids
		true
	end

	def update_node_info(nid, address, name, rsids, location)
		node = get_node(nid)
		if node.address == address && node.name == name &&
				node.rsids == rsids && node.location == location
			return false
		end
		@nodes.update(nid, address, name, rsids, location)
		update_active_rsids
		true
	end

	def get_node(nid)
		node = @nodes.get(nid)
		unless node
			raise "no such node id: #{nid.inspect}"
		end
		node
	end

	def get_all_nodes
		@nodes.get_all_nodes
	end

	def get_all_nids
		@nodes.get_all_nids
	end

	def get_active_rsids
		@active_rsids
	end

	def include?(nid)
		@nodes.include?(nid)
	end

	def get_hash
		@nodes.get_hash
	end

	def to_msgpack(out = '')
		@nodes.to_msgpack(out)
	end

	def from_msgpack(obj)
		@nodes.from_msgpack(obj)
		update_active_rsids
		self
	end

	private
	def update_active_rsids
		map = {}
		@nodes.get_all_nodes.each {|node|
			node.rsids.each {|rsid|
				map[rsid] = nil
			}
		}
		@active_rsids = map.keys.sort
	end
end


end
