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


class SnapshotBus < Bus
	call_slot :get_snapshot_list
	call_slot :get_current_sid
end


class SnapshotService < Service
	def initialize
		@slist = SnapshotList.new
	end

	def run
		@snapshot_path = ConfigBus.get_snapshot_path
		@slist.open(@snapshot_path) if @snapshot_path
		on_change
	end

	def shutdown
		@slist.close if @snapshot_path
	end

	def get_snapshot_list
		@slist.get_list
	end

	def get_current_sid
		@slist.last_sid
	end

	def stat_snapshot_info
		@slist
	end

	def on_change
	end

	ebus_connect :SnapshotBus,
		:get_snapshot_list,
		:get_current_sid

	ebus_connect :StatBus,
		:snapshot_info => :stat_snapshot_info

	ebus_connect :ProcessBus,
		:run,
		:shutdown
end


class SnapshotManagerService < SnapshotService
	def initialize
		super
	end

	def add_snapshot(name)
		ss = @slist.add(name)
		on_change
		ss
	end

	def rpc_add_snapshot(name)
		ss = add_snapshot(name)
		ss.sid
	end

	def on_change
		SyncBus.update(SYNC_SNAPSHOT,
							@slist, @slist.get_hash)
		super
	end

	ebus_connect :CSRPCBus,
		:add_snapshot => :rpc_add_snapshot
end


class SnapshotMemberService < SnapshotService
	def initialize
		super
	end

	def run
		super

		SyncBus.register_callback(SYNC_SNAPSHOT,
							@slist.get_hash) do |obj|
			@slist.from_msgpack(obj)
			on_change
			@slist.get_hash
		end
	end
end


end
