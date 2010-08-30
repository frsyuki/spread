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


class ReplsetInfoService < Service
	def initialize
		super()

		replset_path = ebus_call(:get_replset_path)
		@replset_info = ReplsetInfo.new
		@replset_info.read(replset_path)

		@replset_info.each {|rsid, info|
			$log.trace "replset #{rsid}: #{info}"
		}
	end

	attr_reader :replset_info

	def create(rsid)
		if @replset_info.create(rsid)
			ebus_signal :replset_info_changed, @replset_info
			@replset_info.write
			return true
		end
		nil
	end

	def join_replset(rsid, nid)
		if @replset_info.join(rsid, nid)
			ebus_signal :replset_info_changed, @replset_info
			@replset_info.write
			return true
		end
		nil
	end

	def activate_replset(rsid)
		if @replset_info.activate!(rsid)
			ebus_signal :replset_info_changed, @replset_info
			@replset_info.write
			return true
		end
		nil
	end

	def deactivate_replset(rsid)
		if @replset_info.deactivate!(rsid)
			ebus_signal :replset_info_changed, @replset_info
			@replset_info.write
			return true
		end
		nil
	end

	def rpc_get_replset_info
		@replset_info
	end

	# TODO
	def choice_replset(key)
		replsets = []
		@replset_info.each {|rsid,info|
			if info.active?
				replsets << rsid
			end
		}
		replsets.shuffle.first
	end

	ebus_connect :get_replset_info, :replset_info
	ebus_connect :rpc_create_replset, :create
	ebus_connect :rpc_join_replset, :join_replset
	ebus_connect :rpc_activate_replset, :activate_replset
	ebus_connect :rpc_deactivate_replset, :deactivate_replset
	ebus_connect :rpc_get_replset_info
	ebus_connect :choice_replset
end


end

