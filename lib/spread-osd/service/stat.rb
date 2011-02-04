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


class StatBus < Bus
	call_slot :membership_info
	call_slot :fault_info
	call_slot :replset_info

	call_slot :db_items
	call_slot :cmd_read
	call_slot :cmd_write
	call_slot :cmd_remove
end


class StatService < Service
	def initialize
		@methods = {}
		public_methods.each {|name|
			if name =~ /^stat_(.*)$/
				@methods[$~[1]] = method(name)
			end
		}

		@start_time = Time.now
	end

	def rpc_stat(cmd)
		if m = @methods[cmd]
			m.call
		else
			raise "no such status"
		end
	end

	def stat_uptime
		uptime = Time.now - @start_time
		uptime.to_i
	end

	def stat_time
		Time.now.utc.to_i
	end

	def stat_pid
		Process.pid
	end

	def stat_version
		VERSION
	end

	def stat_cs_address
		ConfigBus.get_cs_address
	end

	def stat_nodes
		StatBus.membership_info
	end

	def stat_fault
		StatBus.fault_info
	end

	def stat_replset
		StatBus.replset_info
	end

	ebus_connect :RPCBus,
		:stat => :rpc_stat
end


end
