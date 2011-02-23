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


class ReadOnlyGatewayService < GatewayService
	def initialize
		@rover = ConfigBus.read_only_version
	end

	def rpc_get_impl(version, key)
		super(version||@rover, key)
	end

	def rpc_get_data_impl(version, key)
		super(version||@rover, key)
	end

	def rpc_get_attrs_impl(version, key)
		super(version||@rover, key)
	end

	def rpc_read_impl(version, key, offset, size)
		super(version||@rover, key, offset, size)
	end

	def rpc_add(key, data, attrs)
		raise_read_only_error
	end

	def rpc_add_data(key, data)
		raise_read_only_error
	end

	def rpc_addv(vname, key, data, attrs)
		raise_read_only_error
	end

	def rpc_addv_data(vname, key, attrs)
		raise_read_only_error
	end

	def rpc_update_attrs(key, attrs)
		raise_read_only_error
	end

	def rpc_delete(key)
		raise_read_only_error
	end

	def rpc_deletet(vtime, key)
		raise_read_only_error
	end

	def rpc_deletev(vname, key)
		raise_read_only_error
	end

	def rpc_remove(key)
		raise_read_only_error
	end

	def rpc_url_impl(version, key)
		super(version||@rover, key)
	end

	private
	def raise_read_only_error
		ar = MessagePack::RPC::AsyncResult.new
		ar.error("read-only mode")
		ar
	end
end


end
