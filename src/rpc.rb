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


class RPCDispatcher
	extend EventBus::Connector

	def initialize
		ebus_connect!
	end

	def heartbeat(hbreq)
		hbreq = HeartbeatRequest.new.from_msgpack(hbreq)
		dispatch(:heartbeat, hbreq)
	end

	def add_node(nid)
		dispatch(:add_node, nid)
	end

	def remove_node(nid)
		dispatch(:remove_node, nid)
	end

	def recover_fault(nid)
		dispatch(:recover_fault, nid)
	end

	def get_nodes_info
		dispatch(:get_nodes_info)
	end

	def get_fault_info
		dispatch(:get_fault_info)
	end

	def get_replset_info
		dispatch(:get_replset_info)
	end

	def create_replset(rsid)
		dispatch(:create_replset, rsid)
	end

	def join_replset(rsid, nid)
		dispatch(:join_replset, rsid, nid)
	end

	def activate_replset(rsid)
		dispatch(:activate_replset, rsid)
	end

	def deactivate_replset(rsid)
		dispatch(:deactivate_replset, rsid)
	end

	def get_object(oid)
		dispatch(:get_object, oid)
	end

	def add_object(oid, data)
		dispatch(:add_object, oid, data)
	end

	def get(key_seq)
		dispatch(:get, key_seq)
	end

	def add(key_seq, attributes, data)
		dispatch(:add, key_seq, attributes, data)
	end

	def register(node)
		node = Node.new.from_msgpack(node)
		dispatch(:register, node)
	end

	def recognized_nodes
		dispatch(:recognized_nodes)
	end

	def add_key(key_seq, attributes)
		dispatch(:add_key, key_seq, attributes)
	end

	def get_key(key_seq)
		dispatch(:get_key, key_seq)
	end

	def get_child_keys(key_seq, skip, limit)
		dispatch(:get_child_keys, key_seq, skip, limit)
	end

	def remove_key(key_seq)
		dispatch(:remove_key, key_seq)
	end

	def set_attributes(key_seq, attributes)
		dispatch(:set_attributes, key_seq, attributes)
	end

	private

	def dispatch(name, *args)
		$log.trace { "rpc: #{name} #{args}" }
		ebus_call("rpc_#{name}".to_sym, *args)
	rescue => e
		msg = ["rpc error on #{name}: #{e}"]
		e.backtrace.each {|bt| msg <<  "    #{bt}" }
		$log.error msg.join("\n")
		raise
	end
end


AsyncResult = MessagePack::RPC::AsyncResult


end

