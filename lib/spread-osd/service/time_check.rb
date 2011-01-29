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


class TimeCheckService < Service
	THRESHOLD = 3
	INTERVAL = 60*10

	def check_blocking!
		do_check.join
		nil
	end

	def run
		@timer = ProcessBus.start_timer(INTERVAL, true) do
			on_timer
		end
	end

	def shutdown
		# FIXME stop @timer
		@timer = nil
	end

	def on_timer
		do_check if @timer
	end

	ebus_connect :ProcessBus,
		:run,
		:shutdown

	private
	def do_check
		get_cs_session.callback(:stat, 'time') do |future|
			begin
				cs_time = future.get
				ack_check(cs_time)
			rescue
				$log.error "time check error: #{$!}"
				$log.error $!.backtrace.pretty_inspect
			end
		end
	end

	def ack_check(cs_time)
		my_time = StatService.instance.stat_time
		diff = cs_time - my_time
		diff_abs = diff > 0 ? diff : -diff
		if diff_abs >= THRESHOLD
			cs_utc = Time.at(cs_time).utc
			my_utc = Time.at(my_time).utc
			$log.warn "sytem time must be adjusted:  cs=[#{cs_utc}]  me=[#{my_utc}]"
		end
	end

	private
	def get_cs_session
		ProcessBus.get_session(ConfigBus.get_cs_address)
	end
end


end
