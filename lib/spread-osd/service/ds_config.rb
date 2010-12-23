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


class DSConfigService < ConfigService
	def initialize
		super
	end

	def run
		@self_node = Node.new(@self_nid, @self_address, @self_name, @self_rsids)
	end

	attr_accessor :self_nid
	attr_accessor :self_name
	attr_accessor :self_address
	attr_accessor :self_rsids
	attr_accessor :cs_address

	attr_accessor :fault_path
	attr_accessor :membership_path

	attr_accessor :storage_path
	attr_accessor :ulog_path
	attr_accessor :rlog_path

	attr_reader :self_node

	ebus_connect :self_nid
	ebus_connect :self_name
	ebus_connect :self_address
	ebus_connect :self_rsids
	ebus_connect :self_node
	ebus_connect :get_cs_address, :cs_address
	ebus_connect :get_storage_path, :storage_path
	ebus_connect :get_ulog_path, :ulog_path
	ebus_connect :get_rlog_path, :rlog_path

	ebus_connect :get_fault_path, :fault_path
	ebus_connect :get_membership_path, :membership_path

	ebus_connect :run
end


end
