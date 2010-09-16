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


class MetadataService < Service
	def initialize
		super()
		@db = NestedDB.new
	end

	def run
		path = ebus_call(:get_mds_db_path)
		@db.open(path)
	end

	def shutdown
		@db.close
	end

	def add_key(key_seq, attributes)
		key = NestedDB.join_key(key_seq)
		oid = ebus_call(:generate_next_oid)
		replset = ebus_call(:choice_next_replset, key)
		obj = NestedDB::Object.new(replset, oid, attributes)
		@db.set(key, obj)
		[replset, oid]
	end

	def get_key(key_seq)
		key = NestedDB.join_key(key_seq)
		obj = @db.get(key)
		unless obj
			return nil
		end
		[obj.replset, obj.oid, obj.attributes]
	end

	def get_child_keys(key_seq, skip, limit)
		key = NestedDB.join_key(key_seq)
		@db.get_child_keys(key, skip, limit).map {|key|
			key.split("\0")
		}
	end

	def set_attributes(key_seq, attributes)
		key = NestedDB.join_key(key_seq)
		@db.modify_attributes(key, attributes)
	end

	def remove_key(key_seq)
		key = NestedDB.join_key(key_seq)
		@db.remove(key)
	end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :rpc_add_key, :add_key
	ebus_connect :rpc_get_key, :get_key
	ebus_connect :rpc_get_child_keys, :get_child_keys
	ebus_connect :rpc_set_attributes, :set_attributes
	ebus_connect :rpc_remove_key, :remove_key
end


end

