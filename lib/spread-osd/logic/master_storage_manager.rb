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


class MasterStorageManager
	def initialize(manager)
		@manager = manager
	end

	def open(ulog_path, storage)
		@ulog = UpdateLog.open(ulog_path)
		@storage = storage
	end

	def close
		@ulog.close
	end

	def set(key, data)
		@ulog.append(key) do
			@storage.set(key, data)
		end
		true
	end

	def remove(key)
		@ulog.append(key) do
			@storage.remove(key)
		end
		true
	end

	def replicate_pull(offset, limit)
		keys = []
		msgs = []
		size = 0
		while true
			key, noffset = @ulog.get(offset)
			unless key
				break
			end
			if keys.include?(key)
				offset = noffset
			else
				data = @storage.get(key)  # data may be null
				msgs << [key, data]
				keys << key
				size += data.size if data
				offset = noffset
				break if size > limit
			end
		end
		[offset, msgs]
	end

	def get_items
		@storage.get_items
	end
end


end
