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


class StorageClientService < Service
	def initialize
		super
	end

	def get(rsid, key, &block)
		nids = ebus_call(:get_replset_nids, rsid).dup

		ha_call(nids, :get, key) do |data,error|
			# FIXME error
			block.call(data)
		end

		nil
	end

	def set(rsid, key, data, &block)
		nids = ebus_call(:get_replset_nids, rsid).dup

		ha_call(nids, :set, key, data) do |success,error|
			# FIXME error
			block.call(success || false)
		end
	end

	def remove(rsid, key, &block)
		nids = ebus_call(:get_replset_nids, rsid).dup

		ha_call(nids, :remove, key) do |success,error|
			# FIXME error
			block.call(success || false)
		end
	end

	private
	def ha_call(nids, *args, &block)
		active_nids = nids.dup
		active_nids.reject! {|nid|
			ebus_call(:is_fault, nid)
		}
		if active_nids.empty?
			# FIXME
			active_nids = nids.dup
		end
		ha_call_impl(active_nids, *args, &block)
	end

	def ha_call_impl(nids, *args, &block)
		nid = nids.pop
		ebus_call(:get_session_nid, nid).callback(*args) do |future|
			if future.error
				$log.warn future.error  # FIXME log
				if nids.empty?
					block.call(nil, future.error)
				else
					ha_call(nids, *args, &block)
				end
			else
				block.call(future.result, nil)
			end
		end
	end
end


end
