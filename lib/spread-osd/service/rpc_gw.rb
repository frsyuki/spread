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


class GWRPCBus < Bus
	call_slot :get
	call_slot :get_data
	call_slot :get_attrs
	call_slot :gets
	call_slot :gets_data
	call_slot :gets_attrs
	call_slot :read
	call_slot :reads
	call_slot :getd_data
	call_slot :readd
	call_slot :set
	call_slot :set_data
	call_slot :set_attrs
	call_slot :remove
	call_slot :select
	call_slot :selects
	call_slot :url
	call_slot :urls
end


class GWRPCService < RPCService
	def get(key)
		dispatch(GWRPCBus, :get, key)
	end

	def get_data(key)
		dispatch(GWRPCBus, :get_data, key)
	end

	def get_attrs(key)
		dispatch(GWRPCBus, :get_attrs, key)
	end


	def gets(sid, key)
		dispatch(GWRPCBus, :gets, sid, key)
	end

	def gets_data(sid, key)
		dispatch(GWRPCBus, :gets_data, sid, key)
	end

	def gets_attrs(sid, key)
		dispatch(GWRPCBus, :gets_attrs, sid, key)
	end


	def read(key, offset, size)
		dispatch(GWRPCBus, :read, key, offset, size)
	end

	def reads(sid, key, offset, size)
		dispatch(GWRPCBus, :reads, sid, key, offset, size)
	end


	def getd_data(okey)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(GWRPCBus, :getd_data, okey)
	end

	def readd(okey, offset, size)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(GWRPCBus, :readd, okey, offset, size)
	end


	def set(key, data, attrs)
		force_binary!(data)
		dispatch(GWRPCBus, :set, key, data, attrs)
	end

	def set_data(key, data)
		force_binary!(data)
		dispatch(GWRPCBus, :set_data, key, data)
	end

	def set_attrs(key, attrs)
		dispatch(GWRPCBus, :set_attrs, key, attrs)
	end


	#def write(key, offset, data)
	#	force_binary!(data)
	#	dispatch(GWRPCBus, :write, key, offset, data)
	#end

	#def resize(key, size)
	#	dispatch(GWRPCBus, :resize, key, size)
	#end

	#def append(key, data)
	#	force_binary!(data)
	#	dispatch(GWRPCBus, :append, key, data)
	#end


	def remove(key)
		dispatch(GWRPCBus, :remove, key)
	end

	#def remove_attrs(key)
	#	dispatch(GWRPCBus, :remove_attrs, key)
	#end


	#def purge(key)
	#	dispatch(GWRPCBus, :purge, key)
	#end


	def select(cols, conds, order, order_col, limit, skip)
		dispatch(GWRPCBus, :select, cols, conds, order, order_col, limit, skip)
	end

	def selects(sid, cols, conds, order, order_col, limit, skip)
		dispatch(GWRPCBus, :selects, sid, cols, conds, order, order_col, limit, skip)
	end


	def url(key)
		dispatch(GWRPCBus, :url, key)
	end

	def urls(sid, key)
		dispatch(GWRPCBus, :urls, sid, key)
	end


	def stat(cmd)
		dispatch(RPCBus, :stat, cmd)
	end
end


end
