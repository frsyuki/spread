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


class GWConfigService < ConfigService
	def initialize
		super
	end

	attr_accessor :cs_address

	attr_accessor :fault_path
	attr_accessor :membership_path

	ebus_connect :get_cs_address, :cs_address

	ebus_connect :get_fault_path, :fault_path
	ebus_connect :get_membership_path, :membership_path
end


end
