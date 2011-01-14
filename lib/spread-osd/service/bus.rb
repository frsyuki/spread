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


class Bus < EventBus::Bus
	def self.ebus_call_log(method, args, &block)
		$log.trace { "ebus call #{method}" }
	end

	def self.ebus_signal_log(methods, args, &block)
		$log.trace { "ebus signal #{methods.join(', ')}" }
	end

	def self.ebus_signal_error(err)
		$log.warn err
		$log.debug_backtrace err.backtrace
	end
end


end
