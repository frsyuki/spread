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


class SlaveStorageService < Service
	def initialize
		super()
		@dir_path = nil
		@dbmap = {}   # {nid => LogStorage}
		@index = ebus_call(:get_storage_index)
	end

	def get_slave_storage
		self
	end

	def open(dir_path)
		@dir_path = dir_path
	end

	def close
		@dbmap.each_pair {|nid,db|
			db.close
		}
	end

	def read(nid, lskey)
		db = @dbmap[nid]
		unless db
			return nil
		end
		db.read(lskey)
	end

	def replicate(nid, seqid, rlskey, data)
		db = @dbmap[nid]
		unless db
			return nil
		end
		if db.last_offset != rlskey.offset
			return false
		end
		db.replicate(rslkey.sidx, data) {|lskey|
			if lskey.size != rlskey.size
				raise "invlaid replication data"
			end
		}
	end

	def replset_info_changed(replset_info)
		# FIXME
	end

	ebus_connect :get_slave_storage
	ebus_connect :replset_info_changed
end


end

