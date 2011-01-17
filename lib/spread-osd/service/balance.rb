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


class BalanceBus < Bus
	call_slot :select_next_rsid
	signal_slot :update_weight
end


class RoutRobinWeightBalanceService < Service
	def initialize
		@array = []
		#@random = Random.new
		@rr = 0
	end

	def update_weight(active_rsids=nil)
		active_rsids ||= MembershipBus.get_active_rsids
		array = []
		active_rsids.each {|rsid|
			w = WeightBus.get_weight(rsid)
			w.times {
				array << rsid
			}
		}
		#@array = array.sort_by {|rsid| @random.rand }
		@array = array.sort_by {|rsid| rand }
	end

	def select_next_rsid(key)
		if @array.empty?
			raise "no replication set is registered"
		end
		@rr += 1
		@rr = 0 if @rr >= @array.size
		@array[@rr]
	end

	ebus_connect :BalanceBus,
		:select_next_rsid,
		:update_weight
end


end
