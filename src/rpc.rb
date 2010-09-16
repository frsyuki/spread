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


	def attach_node(nids)
		dispatch(:attach_node, nids)
	end

	def detach_node(nids)
		dispatch(:detach_node, nids)
	end

	def recover_node(nids)
		dispatch(:recover_node, nids)
	end

	def get_node_list
		dispatch(:get_node_list)
	end

	def get_fault_info
		dispatch(:get_fault_info)
	end

	def get_new_nodes
		dispatch(:get_new_nodes)
	end

	def add_new_node(node)
		node = Node.new.from_msgpack(node)
		dispatch(:add_new_node, node)
	end

	def get_replset_info
		dispatch(:get_replset_info)
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

	def set_attributes(key_seq, attributes)
		dispatch(:set_attributes, key_seq, attributes)
	end

	def remove_key(key_seq)
		dispatch(:remove_key, key_seq)
	end


	def get_object(key_seq)
		dispatch(:get_object, key_seq)
	end

	def add_object(key_seq, attributes, data)
		dispatch(:add_object, key_seq, attributes, data)
	end

	def get_object_attributes(key_seq)
		dispatch(:get_object_attributes, key_seq)
	end

	def set_object_attributes(key_seq, attributes)
		dispatch(:set_object_attributes, key_seq, attributes)
	end


	def add_object_direct(oid, data)
		dispatch(:add_object_direct, oid, data)
	end

	def get_object_direct(oid)
		dispatch(:get_object_direct, oid)
	end


	def replicate_pull(sidx, offset, limit)
		dispatch(:replicate_pull, sidx, offset, limit)
	end

	def replicate_request(nid)
		dispatch(:replicate_request, nid)
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

