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


class StorageManager
	def initialize(self_nid)
		@self_nid = self_nid
		@master = MasterStorageManager.new(self)
		@slave = SlaveStorageManager.new(self)
	end

	def open(storage_path, ulog_path, rlog_path)
		@storage = Storage.open(storage_path)
		@master.open(ulog_path, @storage)
		@slave.open(rlog_path, @storage)
	end

	def close
		@slave.close
		@master.close
		@storage.close
	end

	def get(key)
		@storage.get(key)
	end

	def set(key, data)
		@master.set(key, data)
	end

	def remove(key)
		@master.remove(key)
	end

	def replicate_pull(offset, limit)
		@master.replicate_pull(offset, limit)
	end

	def try_pull(nid, session)
		@slave.try_pull(nid, session)
	end

	def get_items
		@master.get_items
	end

	attr_reader :self_nid
end


end
