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


class DataClientBus < Bus
	# @return
	#   found: raw data
	#   not found: nil
	call_slot :get

	# @return
	#   found: raw data
	#   not found: nil
	call_slot :read

	# @return nil
	call_slot :set

	# @return nil
	call_slot :write

	# @return nil
	#call_slot :resize
end


class DataClientService < Service
	def get(okey, &cb)
		call_rsid(okey, :get_direct, okey, &cb)
	end

	def read(okey, offset, size, &cb)
		call_rsid(okey, :read_direct, okey, offset, size, &cb)
	end

	def set(okey, data, &cb)
		call_rsid(okey, :set_direct, okey, data, &cb)
	end

	def write(okey, offset, data, &cb)
		call_rsid(okey, :write_direct, okey, offset, data, &cb)
	end

	#def resize(okey, size, &cb)
	#	call_rsid(okey, :resize_direct, okey, size)
	#end

	ebus_connect :DataClientBus,
		:get,
		:read,
		:set,
		:write

	private
	def call_rsid(okey, *args, &cb)
		nids = MembershipBus.get_replset_nids(okey.rsid)
		target_nids = select_master(nids, okey.key)
		target_nids.reject! {|nid|
			MembershipBus.is_fault(nid)
		}
		if target_nids.empty?
			# FIXME
			target_nids = nids.dup
		end
		ha_call(target_nids, args, &cb)
	rescue
		cb.call(nil, $!)
	end

	def select_master(nids, key)
		digest = Digest::MD5.digest(key)
		i = digest.unpack('C')[0]
		n = i % nids.size
		return nids[-n,n] + nids[0, nids.size-n]
	end

	def ha_call(nids, args, &cb)
		nid = nids.shift
		MembershipBus.get_session_nid(nid).callback(*args) do |f|
			if f.error
				if nids.empty?
					cb.call(nil, f.error)
				else
					ha_call(nids, args, &cb)
				end
			else
				cb.call(f.result, nil)
			end
		end
	end
end


end
