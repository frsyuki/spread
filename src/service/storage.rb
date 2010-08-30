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


class StorageService < Service
	def initialize
		super()
		@self_nid = ebus_call(:self_nid)
		@master = ebus_call(:get_master_storage)
		@slave = ebus_call(:get_slave_storage)
		@index = ebus_call(:get_storage_index)
	end

	def run
		dir_path = ebus_call(:get_store_path)
		@index.open("#{dir_path}/index.tch")
		@slave.open(dir_path)
		@master.open(dir_path)
	end

	def shutdown
		@master.close
		@slave.close
		@index.close
	end

	def get(oid)
		nid, lskey = @index.get(oid)
		unless nid
			return nil
		end
		if nid == @self_nid
			@master.read(lskey)
		else
			@slave.read(nid, lskey)
		end
	end

	def add(oid, data)
		@master.add(oid, data)
		true
	end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :rpc_get_object, :get
	ebus_connect :rpc_add_object, :add
end


end

