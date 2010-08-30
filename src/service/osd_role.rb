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


class OSDRoleService < Service
	def initialize
		super()
		role_config
		LocatorService.init
		StorageIndexService.init
		MasterStorageService.init
		SlaveStorageService.init
		StorageService.init
	end

	def role_config
		role_data = ebus_call(:role_data)
		data = role_data['osd'] || {}

		@store_path = data["store_path"]
		raise "store_path field is required on osd role" unless @store_path
	end

	attr_reader :store_path

	def run
	end

	def shutdown
	end

	ebus_connect :get_store_path, :store_path

	ebus_connect :run
	ebus_connect :shutdown
end


end

