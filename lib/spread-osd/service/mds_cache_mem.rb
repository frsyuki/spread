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


class LocalMemoryMDSCache < MDSCache
	MDSCacheSelector.register(:local, self)

	def initialize
		require 'tokyocabinet'
	end

	def open(expr)
		@db = TokyoCabinet::ADB.new
		if expr.empty?
			@size = "32m"
		else
			@size = expr
		end
		name = "+#capsiz=#{@size}"
		unless @db.open(name)
			raise "failed to MDS local memory cache database: #{@db.errmsg(@db.ecode)}"
		end
	end

	def close
		@db.close
	end

	def get(key)
		@db[key]
	end

	def set(key, val)
		@db[key] = val
	end

	def invalidate(key)
		@db.delete(key)
	end

	def to_s
		"<LocalMemoryMDSCache size=#{@size}>"
	end
end


end
