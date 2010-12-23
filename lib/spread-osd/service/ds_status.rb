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


class DSStatusService < StatusService
	def initialize
		super
	end

	def stat_db_items
		ebus_call(:stat_db_items)
	end

	def stat_cmd_get
		ebus_call(:stat_cmd_get)
	end

	def stat_cmd_set
		ebus_call(:stat_cmd_set)
	end

	def stat_cmd_remove
		ebus_call(:stat_cmd_remove)
	end
end


end
