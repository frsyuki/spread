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


class StorageService < Service
	def initialize
		super
		@self_nid = ebus_call(:self_nid)
		@self_rsids = ebus_call(:self_rsids)
		@manager = StorageManager.new(@self_nid)
		@stat_cmd_get = 0
		@stat_cmd_set = 0
		@stat_cmd_remove = 0
	end

	def run
		storage_path = ebus_call(:get_storage_path)
		ulog_path = ebus_call(:get_ulog_path)
		rlog_path = ebus_call(:get_rlog_path)
		@manager.open(storage_path, ulog_path, rlog_path)
	end

	def shutdown
		@manager.close
	end

	def rpc_get(key)
		@stat_cmd_get += 1
		@manager.get(key)
	end
	
	def rpc_set(key, data)
		@stat_cmd_set += 1
		@manager.set(key, data)
	end

	def rpc_remove(key)
		@stat_cmd_remove += 1
		@manager.remove(key)
	end

	def rpc_replicate_pull(offset, limit)
		@manager.replicate_pull(offset, limit)
	end

	def rpc_replicate_notify(nid)
		session = ebus_call(:get_session_nid, nid)
		@manager.try_pull(nid, session)
		nil
	end

	def stat_db_items
		@manager.get_items
	end

	attr_reader :stat_cmd_get
	attr_reader :stat_cmd_set
	attr_reader :stat_cmd_remove

	def on_timer
		nids = []
		@self_rsids.each {|rsid|
			begin
				nids.concat ebus_call(:get_replset_nids, rsid)
			rescue
			end
		}
		nids.uniq.each {|nid|
			if nid != @self_nid && !ebus_call(:is_fault, nid)
				session = ebus_call(:get_session_nid, nid)
				@manager.try_pull(nid, session)
			end
		}
	end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :rpc_get
	ebus_connect :rpc_set
	ebus_connect :rpc_remove
	ebus_connect :rpc_replicate_pull
	ebus_connect :rpc_replicate_notify
	ebus_connect :on_timer
	ebus_connect :stat_db_items
	ebus_connect :stat_cmd_get
	ebus_connect :stat_cmd_set
	ebus_connect :stat_cmd_remove
end


end
