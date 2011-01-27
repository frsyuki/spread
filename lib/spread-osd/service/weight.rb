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


class WeightBus < Bus
	call_slot :get_weight
	call_slot :get_registered_rsids

	call_slot :set_weight

	call_slot :set_active_rsids
	call_slot :select_next_rsid
end


class WeightService < Service
	def initialize
		@winfo = WeightInfo.new
	end

	def run
		@weight_path = ConfigBus.get_weight_path
		@winfo.open(@weight_path) if @weight_path
		on_change
	end

	def shutdown
		@winfo.close if @weight_path
	end

	def get_weight(rsid)
		@winfo.get_weight(rsid)
	end

	def get_registered_rsids
		@winfo.get_registered_rsids
	end

	def on_change
		BalanceBus.update_weight
	end

	ebus_connect :WeightBus,
		:get_weight,
		:get_registered_rsids

	ebus_connect :ProcessBus,
		:run,
		:shutdown
end


class WeightManagerService < WeightService
	def initialize
		super
	end

	def set_weight(rsid, weight)
		if @winfo.set_weight(rsid, weight)
			on_change
			true
		else
			false
		end
	end

	def reset_weight(rsid)
		if @winfo.reset_weight(rsid)
			on_change
			true
		else
			false
		end
	end

	def rpc_set_replset_weight(rsid, weight)
		set_weight(rsid, weight)
	end

	def rpc_reset_replset_weight(rsid)
		reset_weight(rsid)
	end

	ebus_connect :WeightBus,
		:set_weight

	ebus_connect :CSRPCBus,
		:set_replset_weight => :rpc_set_replset_weight,
		:reset_replset_weight => :rpc_reset_replset_weight

	private
	def on_change
		SyncBus.update(SYNC_REPLSET_WEIGHT,
							@winfo, @winfo.get_hash)
		super
	end
end


class WeightMemberService < WeightService
	def initialize
		super
	end

	def run
		super

		SyncBus.register_callback(SYNC_REPLSET_WEIGHT,
							@winfo.get_hash) do |obj|
			@winfo.from_msgpack(obj)
			on_change
			@winfo.get_hash
		end
	end
end


end
