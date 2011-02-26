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


class DSRPCBus < Bus
	call_slot :get_direct
	call_slot :set_direct
	call_slot :delete_direct
	call_slot :copy
	call_slot :read_direct
	call_slot :url_direct
	#call_slot :write_direct
	#call_slot :append_direct
	call_slot :resize_direct
	call_slot :replicate_pull
	call_slot :replicate_notify
end


class DSRPCService < GWRPCService
	def get_direct(okey)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(DSRPCBus, :get_direct, okey)
	end

	def set_direct(okey, data)
		okey = ObjectKey.new.from_msgpack(okey)
		force_binary!(data)
		dispatch(DSRPCBus, :set_direct, okey, data)
	end

	def delete_direct(okey)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(DSRPCBus, :delete_direct, okey)
	end

	#def copy(okey, noid)
	#	okey = ObjectKey.new.from_msgpack(okey)
	#	noid = ObjectKey.new.from_msgpack(noid)
	#	dispatch(DSRPCBus, :copy, okey, noid)
	#end

	def read_direct(okey, offset, size)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(DSRPCBus, :read_direct, okey, offset, size)
	end

	#def write_direct(okey, offset, data)
	#	okey = ObjectKey.new.from_msgpack(okey)
	#	force_binary!(data)
	#	dispatch(DSRPCBus, :write_direct, okey, offset, data)
	#end

	#def append_direct(okey, data)
	#	okey = ObjectKey.new.from_msgpack(okey)
	#	force_binary!(data)
	#	dispatch(DSRPCBus, :append_direct, okey, data)
	#end

	def url_direct(okey)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(DSRPCBus, :url_direct, okey)
	end

	def resize_direct(okey, size)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(DSRPCBus, :resize_direct, okey, size)
	end

	def replicate_pull(pos, limit)
		dispatch(DSRPCBus, :replicate_pull, pos, limit)
	end

	def replicate_notify(nid)
		dispatch(DSRPCBus, :replicate_notify, nid)
	end
end


end
