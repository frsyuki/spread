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
	def initialize
		super()
		@self_nid = ebus_call(:self_nid)
		@db = LogStorage.new
		@index = ebus_call(:get_storage_index)
	end

	def get_master_storage
		self
	end

	def open(dir_path)
		@db.open(dir_path, @self_nid.to_s)
	end

	def close
		@db.close
	end

	def add(oid, data)
		v = [oid, data]
		@db.append(v) {|lskey|
			@index.set(oid, @self_nid, lskey)
		}
	end

	def read(lskey)
		oid, data = @db.read(lskey)
		data
	end

	ebus_connect :get_master_storage
end


end

