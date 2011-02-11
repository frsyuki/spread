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


class ConfigBus < Bus
	call_slot :self_nid
	call_slot :self_name
	call_slot :self_address
	call_slot :self_rsids
	call_slot :self_location
	call_slot :self_node
	call_slot :get_storage_path
	call_slot :get_ulog_path
	call_slot :get_rts_path
	call_slot :get_fault_path
	call_slot :get_membership_path
	call_slot :get_weight_path

	call_slot :get_initial_mds_uri
	call_slot :get_initial_mds_cache_uri

	call_slot :http_redirect_port
	call_slot :http_redirect_path_format

	call_slot :get_cs_address
	call_slot :read_only_version
	call_slot :http_gateway_address
end


class ConfigService < Service
	attr_accessor :fault_path
	attr_accessor :membership_path
	attr_accessor :weight_path

	ebus_connect :ConfigBus,
		:get_fault_path      => :fault_path,
		:get_membership_path => :membership_path,
		:get_weight_path     => :weight_path
end


end
