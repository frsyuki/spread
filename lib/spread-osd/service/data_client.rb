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

	# @return
	#   deleted: true
	#   not found: nil
	call_slot :delete

	## @return nil
	#call_slot :write

	# @return nil
	#call_slot :resize

	# @return
	#   found: url string
	#   not found: nil
	call_slot :url
end


class DataClientService < Service
	# TODO localhost optimization if DataServer is connected

	def get(okey, found_expected=false, &cb)
		call_rsid(okey, :get_direct, [okey], found_expected, &cb)
	end

	def read(okey, offset, size, found_expected=false, &cb)
		call_rsid(okey, :read_direct, [okey, offset, size], found_expected, &cb)
	end

	def set(okey, data, &cb)
		call_rsid(okey, :set_direct, [okey, data], &cb)
	end

	def delete(okey, &cb)
		call_rsid(okey, :delete_direct, [okey], &cb)
	end

	#def write(okey, offset, data, &cb)
	#	call_rsid(okey, :write_direct, [okey, offset, data], &cb)
	#end

	#def resize(okey, size, &cb)
	#	call_rsid(okey, :resize_direct, [okey], size)
	#end

	def url(okey, found_expected, &cb)
		call_rsid(okey, :url_direct, [okey], found_expected, &cb)
	end

	ebus_connect :DataClientBus,
		:get,
		:read,
		:set,
		:delete,
		:url

	private
	def call_rsid(okey, method, args, not_nil_required=false, &cb)
		nids = MasterSelectBus.select_master(okey.rsid, okey.key)
		target_nids = nids.reject {|nid|
			MembershipBus.is_fault(nid)
		}
		if target_nids.empty?
			target_nids = nids
		end
		ha_call(target_nids, method, args, not_nil_required, &cb)
	rescue
		cb.call(nil, $!)
	end

	def ha_call(nids, method, args, not_nil_required=false, &cb)
		nid = nids.shift
		MembershipBus.get_session_nid(nid).callback(method, *args) do |f|
			if f.error || (not_nil_required && f.result == nil)
				if nids.empty?
					cb.call(nil, f.error) rescue nil
				else
					ha_call(nids, method, args, not_nil_required, &cb)
				end
			else
				cb.call(f.result, nil) rescue nil
			end
		end
	end
end


end
