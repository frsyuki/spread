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


class GatewayService < Service
	def initialize
		super()
	end

	def rpc_get_object(key_seq)
		ar = MessagePack::RPC::AsyncResult.new
		ebus_call(:metadata_get_key, key_seq) do |result, error|
			if result
				replset, oid, attributes = *result
				nids = ebus_call(:get_replset_nids, replset)  # FIXME error
				nid = nids.first  # FIXME round robin?
				node = ebus_call(:get_node, nid)
				node.session.callback(:get_object_direct, oid) do |future|
					ar.result(future.result, future.error)
				end
			elsif !error
				ar.result(nil)
			else
				ar.error(error)
			end
		end
		ar
	end

	def rpc_add_object(key_seq, attributes, data)
		ar = MessagePack::RPC::AsyncResult.new
		ebus_call(:metadata_add_key, key_seq, attributes) do |result, error|
			if result
				begin
					replset, oid = *result
					nids = ebus_call(:get_replset_nids, replset)
					nid = nids.first
					node = ebus_call(:get_node, nid)
					node.session.callback(:add_object_direct, oid, data) do |future|
						ar.result(future.result, future.error)
					end
				rescue
					ar.error($!.to_s)
				end
			else
				ar.error(error)
			end
		end
		ar
	end

	def rpc_set_object_attributes(key_seq, attributes)
		ar = MessagePack::RPC::AsyncResult.new
		ebus_call(:metadata_set_attributes, key_seq, attributes) do |result, error|
			ar.result(result, error)
		end
		ar
	end

	def rpc_get_object_attributes(key_seq)
		ar = MessagePack::RPC::AsyncResult.new
		ebus_call(:metadata_get_key, key_seq) do |result, error|
			if result
				replset, oid, attributes = *result
				ar.result(attributes)
			elsif !error
				ar.result(nil)
			else
				ar.error(error)
			end
		end
		ar
	end

	def rpc_get_child_keys(key_seq, skip, limit)
		ar = MessagePack::RPC::AsyncResult.new
		ebus_call(:metadata_get_child_keys, key_seq, skip, limit) do |result, error|
			ar.result(result, error)
		end
		ar
	end

	ebus_connect :rpc_get_object
	ebus_connect :rpc_add_object
	ebus_connect :rpc_set_object_attributes
	ebus_connect :rpc_get_object_attributes
	ebus_connect :rpc_get_child_keys
end


end

