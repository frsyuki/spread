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
		@rosid = ConfigBus.read_only_sid
	end

	def rpc_gets(sid, key)
		super(@rosid||sid, key)
	end

	def rpc_gets_data(sid, key)
		super(@rosid||sid, key)
	end

	def rpc_gets_attrs(sid, key)
		super(@rosid||sid, key)
	end

	def rpc_reads(sid, key, offset, size)
		super(@rosid||sid, key, offset, size)
	end

	def rpc_set(key, data, attrs)
		raise_read_only_error
	end

	def rpc_set_data(key, data)
		raise_read_only_error
	end

	def rpc_set_attrs(key, attrs)
		raise_read_only_error
	end

	def rpc_truncate(key, size)
		raise_read_only_error
	end

	def rpc_remove(key)
		raise_read_only_error
	end

	def rpc_selects(sid, cols, conds, order, order_col, limit, skip)
		super(@rosid||sid, cols, conds, order, order_col, limit, skip)
	end

	private
	def raise_read_only_error
		ar = MessagePack::RPC::AsyncResult.new
		ar.error("read-only mode")
		ar
	end
end


end
