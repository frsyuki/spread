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


class FaultInfoService < Service
	def initialize
		super()
		@fault_info = FaultInfo.new
	end

	attr_reader :fault_info

	def fault_nodes_detected(nids)
		if @fault_info.add_nids(nids)
			ebus_signal :fault_info_changed, @fault_info
		end
	end

	def rpc_recover_fault(nid)
		if @fault_info.remove_nid(nid)
			$log.info "recover node #{nid}"
			ebus_signal :fault_info_changed, @fault_info
			true
		else
			nil
		end
	end

	def rpc_get_fault_info
		@fault_info
	end

	ebus_connect :get_fault_info, :fault_info
	ebus_connect :fault_nodes_detected
	ebus_connect :rpc_recover_fault
	ebus_connect :rpc_get_fault_info
end


end

