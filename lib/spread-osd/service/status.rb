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


class StatusService < Service
	def initialize
		super

		@methods = {}
		public_methods.each {|name|
			if name =~ /^stat_(.*)$/
				@methods[$~[1]] = method(name)
			end
		}

		@start_time = Time.now
	end

	def rpc_status(cmd)
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
		Time.now.to_i
	end

	def stat_pid
		Process.pid
	end

	#def stat_version
	#	# FIXME stat_version
	#end

	ebus_connect :rpc_status
end


end
