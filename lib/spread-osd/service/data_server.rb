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


class DataServerService < Service
	def initialize
		@self_nid = ConfigBus.self_nid
		@self_rsids = ConfigBus.self_rsids
		@stat_cmd_read = 0
		@stat_cmd_write = 0
		@stat_cmd_remove = 0
	end

	def rpc_get_direct(okey)
		@stat_cmd_read += 1
		StorageBus.get(okey.vtime, okey.key)
	end
	
	def rpc_read_direct(okey, offset, size)
		@stat_cmd_read += 1
		StorageBus.read(okey.vtime, okey.key, offset, size)
	end
	
	def rpc_set_direct(okey, data)
		@stat_cmd_write += 1
		d = UpdateLogData.new(okey.vtime, okey.key)
		UpdateLogBus.append(d.dump) do
			StorageBus.set(okey.vtime, okey.key, data)
		end
		nil
	end

	#def rpc_write_direct(okey, offset, data)
	#	@stat_cmd_write += 1
	#	d = UpdateLogData.new(okey.vtime, okey.key, offset, data.size)
	#	UpdateLogBus.append(d.dump) do
	#		StorageBus.write(okey.vtime, okey.key, offset, data)
	#	end
	#	nil
	#end

	#def rpc_resize_direct(okey, size)
	#	# TODO: stat_cmd_resize?
	#	# FIXME size field?
	#	d = UpdateLogData.new(okey.vtime, okey.key, nil, size)
	#	UpdateLogBus.append(d.dump) do
	#		StorageBus.resize(okey.vtime, okey.key, size)
	#	end
	#	nil
	#end

	def rpc_exist_direct(okey)
		StorageBus.exist(okey.vtime, okey.key)
	end

	def rpc_remove_direct(okey)
		@stat_cmd_remove += 1
		d = UpdateLogData.new(okey.vtime, okey.key)
		UpdateLogBus.append(d.dump) do
			StorageBus.remove(okey.vtime, okey.key)
		end
		nil
	end

	def rpc_replicate_pull(pos, limit)
		mkeys = []
		msgs = []
		msize = 0
		while true
			raw, npos = UpdateLogBus.get(pos)
			unless raw
				break
			end
			d = UpdateLogData.load(raw)
			# set or remove
			if mkeys.include?(d.key)
				pos = npos
			else
				if d.offset && d.size
					data = StorageBus.read(d.vtime, d.key, d.offset, d.size)
				else
					data = StorageBus.get(d.vtime, d.key)
					mkeys << d.key
				end
				# data may be null => removed
				if data
					msgs << [d.vtime, d.key, d.offset, data]
					msize += data.size
				else
					# data is removed
					msgs << [d.vtime, d.key, 0, nil]
				end
				pos = npos
				break if msize > limit
			end
		end
		[pos, msgs]
	end

	def rpc_replicate_notify(nid)
		session = MembershipBus.get_session_nid(nid)
		SlaveBus.try_replicate(nid, session)
		nil
	end

	def stat_db_items
		StorageBus.get_items
	end

	def on_timer
		nids = []
		@self_rsids.each {|rsid|
			begin
				nids.concat MasterSelectBus.select_master_static(rsid)
			rescue
			end
		}
		done = [@self_nid]
		nids.each {|nid|
			if !done.include?(nid) && !MembershipBus.is_fault(nid)
				session = MembershipBus.get_session_nid(nid)
				SlaveBus.try_replicate(nid, session)
				done << nid
			end
		}
	end

	attr_reader :stat_cmd_read
	attr_reader :stat_cmd_write
	attr_reader :stat_cmd_remove

	ebus_connect :ProcessBus,
		:on_timer

	ebus_connect :StatBus,
		:db_items => :stat_db_items,
		:cmd_read => :stat_cmd_read,
		:cmd_write => :stat_cmd_write,
		:cmd_remove => :stat_cmd_remove

	ebus_connect :DSRPCBus,
		:get_direct       => :rpc_get_direct,
		:set_direct       => :rpc_set_direct,
		:read_direct      => :rpc_read_direct,
		:remove_direct    => :rpc_remove_direct,
		:replicate_pull   => :rpc_replicate_pull,
		:replicate_notify => :rpc_replicate_notify
end


end
