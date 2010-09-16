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


class SlaveStorage < EventBus::Base
	include StorageIndexService::Readable

	def initialize(dir_path, nid, index)
		super()
		@index = index
		@db = LogStorage.new
		@nid = nid
		@db.open(dir_path, nid.to_s)
		ebus_call(:register_storage, nid, self)
		@pulling = false
	end

	def close
		@db.close
	end

	PULL_LIMIT = 100

	def try_pull
		if @pulling
			return nil
		end
		@pulling = true
		begin
			s = ebus_call(:get_node, @nid).session
			offset = @db.get_offset
			s.callback(:rpc_replicate_pull, offset, PULL_LIMIT) do |result,error|
				# TODO
			end
		rescue
			@pulling = false
		end
	end
end


class SlaveStorageService < Service
	def initialize
		super()
		@self_nid = ebus_call(:self_nid)
		@db = LogStorage.new
		@index = ebus_call(:get_storage_index)
		@dir_path = ebus_call(:get_storage_path)
		@open_dbs = {}    # {nid => SlaveStorage}
		@active_dbs = []  # [SlaveStorage]
	end

	def shutdown
		@open_dbs.each {|nid, storage|
			storage.close
		}
	end

	def replset_info_changed(replset_info)
		master_nids = []
		replset_info.each {|rsid,info|
			nids = info.nids.dup
			if nids.delete(@self_nid)
				master_nids.concat(nids)
			end
		}
		master_nids.sort!.uniq!

		@active_dbs = master_nids.map {|nid|
			unless @open_dbs.has_key?(nid)
				$log.trace "open slave storage for nid=#{nid}"
				@open_dbs[nid] = SlaveStorage.new(@dir_path, nid, @index)
			end
			@open_dbs[nid]
		}
	end

	def on_timer
		@active_dbs.each {|storage|
			storage.try_pull
		}
	end

	def rpc_replicate_request(nid)
		if storage = @active_dbs[nid]
			storage.try_pull
			return true
		end
		nil
	end

	ebus_connect :shutdown
	ebus_connect :on_timer
	ebus_connect :replset_info_changed
	ebus_connect :rpc_replicate_request
end


end

