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


class BootInfoService < Service
	def initialize
		super()
		@self_node = nil
		@role_data = {}
		@confsvr_address = nil
	end

	attr_reader :self_node
	attr_reader :role_data
	attr_reader :confsvr_address

	def self_address
		@self_node.address
	end

	def self_nid
		@self_node.nid
	end

	def self_name
		@self_node.name
	end

	def boot_info_loaded(boot)
		@self_node = boot.node
		@role_data = boot.role_data
		@confsvr_address = boot.confsvr
		$log.debug "self: #{@self_node}"
		nil
	end

	ebus_connect :boot_info_loaded
	ebus_connect :self_node
	ebus_connect :self_address
	ebus_connect :self_nid
	ebus_connect :self_name
	ebus_connect :role_data
	ebus_connect :confsvr_address
end


end

