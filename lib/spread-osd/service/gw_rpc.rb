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


class GWRPCService < Service
	def initialize
		super
	end

	def get(key)
		dispatch(:get, key)
	end

	def set(key, map)
		dispatch(:set, key, map)
	end

	def remove(key)
		dispatch(:remove, key)
	end

	def status(cmd)
		dispatch(:status, cmd)
	end

	def get_direct(key, rsid)
		dispatch(:get_direct, key, rsid)
	end

	def set_direct(key, rsid, data)
		dispatch(:set_direct, key, rsid, data)
	end

	def remove_direct(key, rsid)
		dispatch(:remove_direct, key, rsid)
	end

	private
	def dispatch(name, *args)
		$log.trace { "rpc: #{name} #{args}" }
		ebus_call("rpc_#{name}".to_sym, *args)
	rescue => e
		msg = ["rpc error on #{name}: #{e}"]
		e.backtrace.each {|bt| msg <<  "    #{bt}" }
		$log.error msg.join("\n")
		raise
	end

	public
	def self.serve
		$net.serve(instance)
		$net
	end
end


end
