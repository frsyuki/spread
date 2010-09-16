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


class StorageIndexService < Service
	module Readable
		def read_object(lskey)
			oid, data = @db.read(lskey)
			data
		end
	end

	def initialize
		super()
		@index = LogStorageIndex.new
		@dbmap = {}  # {nid => LogStorage readable}
	end

	def get_storage_index
		@index
	end

	def run
		dir_path = ebus_call(:get_storage_path)
		@index.open("#{dir_path}/index.tch")
	end

	def shutdown
		@index.close
	end

	def register_storage(nid, readable)
		@dbmap[nid] = readable
	end

	def get_object(oid)
		nid, lskey = @index.get(oid)
		unless nid
			return nil
		end
		readable = @dbmap[nid]
		unless readable
			return nil
		end
		readable.read_object(lskey)
	end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :get_storage_index
	ebus_connect :register_storage
	ebus_connect :rpc_get_object_direct, :get_object
end


end

