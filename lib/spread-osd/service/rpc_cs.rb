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


class CSRPCBus < Bus
	call_slot :heartbeat
	call_slot :sync_config
	call_slot :add_node
	call_slot :remove_node
	call_slot :update_node_info
	call_slot :recover_node
	call_slot :set_replset_weight
	call_slot :reset_replset_weight
	call_slot :get_mds_uri
	call_slot :set_mds_uri
	call_slot :get_mds_cache_uri
	call_slot :set_mds_cache_uri
end


class CSRPCService < RPCService
	def heartbeat(nid=nil, sync_hash)
		force_binary!(sync_hash) if sync_hash
		dispatch(CSRPCBus, :heartbeat, nid, sync_hash)
	end

	def sync_config(hash_array)
		hash_array = hash_array.map {|str|
			force_binary!(str) if str
		}
		dispatch(CSRPCBus, :sync_config, hash_array)
	end

	def add_node(nid, address, name, rsids, self_location)
		address = Address.load(address)
		dispatch(CSRPCBus, :add_node, nid, address, name, rsids, self_location)
	end

	def remove_node(nid)
		dispatch(CSRPCBus, :remove_node, nid)
	end

	def update_node_info(nid, address, name, rsids)
		address = Address.load(address)
		dispatch(CSRPCBus, :update_node_info, nid, address, name, rsids)
	end

	def recover_node(nid)
		dispatch(CSRPCBus, :recover_node, nid)
	end

	def set_replset_weight(rsid, weight)
		dispatch(CSRPCBus, :set_replset_weight, rsid, weight)
	end

	def reset_replset_weight(rsid)
		dispatch(CSRPCBus, :reset_replset_weight, rsid)
	end

	def get_mds_uri
		dispatch(CSRPCBus, :get_mds_uri)
	end

	def set_mds_uri(uri)
		force_binary!(uri)
		dispatch(CSRPCBus, :set_mds_uri, uri)
	end

	def get_mds_cache_uri
		dispatch(CSRPCBus, :get_mds_cache_uri)
	end

	def set_mds_cache_uri(uri)
		force_binary!(uri)
		dispatch(CSRPCBus, :set_mds_cache_uri, uri)
	end

	def stat(cmd)
		dispatch(RPCBus, :stat, cmd)
	end
end


end
