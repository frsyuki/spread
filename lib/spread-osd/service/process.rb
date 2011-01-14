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


class ProcessBus < Bus
	signal_slot :run
	signal_slot :shutdown
	signal_slot :on_timer
	call_slot :start_timer
	call_slot :submit
	call_slot :get_session
	call_slot :serve_rpc
end


class ProcessService < Service
	def initialize
		@net = MessagePack::RPC::Server.new
		submit_test
	end

	def serve_rpc(dp)
		@net.serve(dp)
		@net
	end

	def run
		@timer = start_timer(1.0, true) do
			ProcessBus.on_timer
		end
	end

	def submit(task=nil, &block)
		task ||= block
		@net.submit(task)
		nil
	end

	def shutdown
		# TODO stop @timer
	end

	def start_timer(interval, periodic, &block)
		@net.start_timer(interval, periodic, &block)
	end

	def get_session(addr)
		@net.get_session(addr)
	end

	ebus_connect :ProcessBus,
		:run,
		:shutdown,
		:serve_rpc,
		:start_timer,
		:submit,
		:get_session

	private
	def submit_test
		@net.submit {
			"ok"
		}
	end
end


end
