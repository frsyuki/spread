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
	call_slot :read
	call_slot :gett
	call_slot :gett_data
	call_slot :gett_attrs
	call_slot :readt
	call_slot :getv
	call_slot :getv_data
	call_slot :getv_attrs
	call_slot :readv
	call_slot :getd_data
	call_slot :readd
	call_slot :add
	call_slot :add_data
	call_slot :addv
	call_slot :addv_data
	call_slot :update_attrs
	call_slot :remove
	call_slot :delete
	call_slot :deletet
	call_slot :deletev
	call_slot :url
	call_slot :urlt
	call_slot :urlv
	call_slot :util_locate
end


class GWRPCService < RPCService
	####
	## get head
	##
	def get(key)
		dispatch(GWRPCBus, :get, key)
	end

	def get_data(key)
		dispatch(GWRPCBus, :get_data, key)
	end

	def get_attrs(key)
		dispatch(GWRPCBus, :get_attrs, key)
	end

	def read(key, offset, size)
		dispatch(GWRPCBus, :read, key, offset, size)
	end


	####
	## time-based get version
	##
	def gett(vtime, key)
		vtime = vtime.to_i  # TODO type check
		dispatch(GWRPCBus, :gett, vtime, key)
	end

	def gett_data(vtime, key)
		vtime = vtime.to_i  # TODO type check
		dispatch(GWRPCBus, :gett_data, vtime, key)
	end

	def gett_attrs(vtime, key)
		vtime = vtime.to_i  # TODO type check
		dispatch(GWRPCBus, :gett_attrs, vtime, key)
	end

	def readt(vtime, key, offset, size)
		vtime = vtime.to_i  # TODO type check
		dispatch(GWRPCBus, :readt, vtime, key, offset, size)
	end


	####
	## name-based get version
	##
	def getv(vname, key)
		vname = vname.to_s  # TODO type check
		dispatch(GWRPCBus, :getv, vname, key)
	end

	def getv_data(vname, key)
		vname = vname.to_s  # TODO type check
		dispatch(GWRPCBus, :getv_data, vname, key)
	end

	def getv_attrs(vname, key)
		vname = vname.to_s  # TODO type check
		dispatch(GWRPCBus, :getv_attrs, vname, key)
	end

	def readv(vname, key, offset, size)
		vname = vname.to_s  # TODO type check
		dispatch(GWRPCBus, :readt, vname, key, offset, size)
	end



	####
	## direct get
	##
	def getd_data(okey)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(GWRPCBus, :getd_data, okey)
	end

	def readd(okey, offset, size)
		okey = ObjectKey.new.from_msgpack(okey)
		dispatch(GWRPCBus, :readd, okey, offset, size)
	end


	####
	## add
	##
	def add(key, data, attrs)
		force_binary!(data)
		dispatch(GWRPCBus, :add, key, data, attrs)
	end

	def add_data(key, data)
		force_binary!(data)
		dispatch(GWRPCBus, :add_data, key, data)
	end


	####
	## add with version name
	##
	def addv(vname, key, data, attrs)
		vname = vname.to_s  # TODO type check
		force_binary!(data)
		dispatch(GWRPCBus, :addv, vname, key, data, attrs)
	end

	def addv_data(vname, key, data)
		vname = vname.to_s  # TODO type check
		force_binary!(data)
		dispatch(GWRPCBus, :addv_data, vname, key, data)
	end


	####
	## in-place update data
	##
	#def write(key, offset, data)
	#	force_binary!(data)
	#	dispatch(GWRPCBus, :write, key, offset, data)
	#end
	#
	#def resize(key, size)
	#	dispatch(GWRPCBus, :resize, key, size)
	#end
	#
	#def append(key, data)
	#	force_binary!(data)
	#	dispatch(GWRPCBus, :append, key, data)
	#end


	####
	## in-place update attributes
	##
	def update_attrs(key, attrs)
		dispatch(GWRPCBus, :update_attrs, key, attrs)
	end


	####
	## remove
	##
	def remove(key)
		dispatch(GWRPCBus, :remove, key)
	end


	####
	## delete
	##
	def delete(key)
		dispatch(GWRPCBus, :delete, key)
	end

	def deletet(vtime, key)
		vtime = vtime.to_i  # TODO type check
		dispatch(GWRPCBus, :deletet, vtime, key)
	end

	def deletev(vname, key)
		vname = vname.to_s  # TODO type check
		dispatch(GWRPCBus, :deletev, vname, key)
	end


	#def purge(key)
	#	dispatch(GWRPCBus, :purge, key)
	#end


	####
	## URL
	##
	def url(key)
		dispatch(GWRPCBus, :url, key)
	end

	def urlt(vtime, key)
		vtime = vtime.to_i  # TODO type check
		dispatch(GWRPCBus, :urlt, vtime, key)
	end

	def urlv(vname, key)
		vname = vname.to_s  # TODO type check
		dispatch(GWRPCBus, :urlv, vname, key)
	end


	####
	## Utility
	##
	def util_locate(key)
		dispatch(GWRPCBus, :util_locate, key)
	end


	def stat(cmd)
		dispatch(RPCBus, :stat, cmd)
	end
end


end
