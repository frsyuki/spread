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


class HashStorage < Storage
	def initialize(path)
		@hash = {}
	end

	def close
		@hash.clear
	end

	def get(key)
		puts "hash storage get: #{key}"
		@hash[key]
	end

	def set(key, data)
		puts "hash storage set: #{key}=#{data}"
		@hash[key] = data.to_s
	end

	def remove(key)
		puts "hash storage remove: #{key}"
		if @hash.delete(key)
			true
		else
			false
		end
	end

	def get_items
		@hash.size
	end
end


end
