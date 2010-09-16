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


class MasterStorageService < Service
	include StorageIndexService::Readable

	def initialize
		super()
		@self_nid = ebus_call(:self_nid)
		@db = LogStorage.new
		@index = ebus_call(:get_storage_index)
		ebus_call(:register_storage, @self_nid, self)
	end

	def run
		dir_path = ebus_call(:get_storage_path)
		@db.open(dir_path, @self_nid.to_s)
	end

	def shutdown
		@db.close
	end

	def add_object(oid, data)
		v = [oid, data]
		@db.append(v) {|lskey|
			@index.set(oid, @self_nid, lskey)
		}
		true
	end

	def rpc_replicate_pull(sidx, offset, limit)
		# TODO
	end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :rpc_add_object_direct, :add_object
	ebus_connect :rpc_replicate_pull
end


end

