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


class StorageBus < Bus
	call_slot :open
	call_slot :close

	call_slot :get

	call_slot :set

	call_slot :read

	call_slot :write

	call_slot :remove

	call_slot :copy

	call_slot :get_items
end


class StorageSelector
	IMPLS = {}

	def self.register(name, klass)
		IMPLS[name.to_sym] = klass
		nil
	end

	def self.select_class(uri)
		if m = /^(\w{1,8})\:(.*)/.match(uri)
			type = m[1].to_sym
			expr = m[2]
		else
			type = :dir
			expr = uri
		end

		klass = IMPLS[type]
		unless klass
			raise "unknown Storage type: #{type}"
		end

		return klass, expr
	end

	def self.select!(uri)
		klass, expr = select_class(uri)
		klass.init

		StorageBus.open(expr)
	end

	def self.open!
		select!(ConfigBus.get_storage_path)
	end
end


class StorageService < Service
	#def open(path)
	#end

	#def close
	#end

	#def get(sid, key)
	#end

	#def set(sid, key, data)
	#end

	#def read(sid, key, offset, size)
	#end

	#def write(sid, key, offset, data)
	#end

	#def remove(sid, key)
	#end

	#def get_items
	#end

	ebus_connect :StorageBus,
		:get,
		:set,
		:read,
		:write,
		:remove,
		:get_items,
		:open,
		:close
end


end
