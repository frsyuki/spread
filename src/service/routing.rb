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
require 'digest/sha1'

module SpreadOSD


class RoutingService < Service
	def initialize
		super()
		@mds_nids = []
		@replset_info = nil
	end

	attr_reader :mds_nids

	def nodes_info_changed(nodes_info)
		mds_nids = []
		nodes_info.nodes.each {|node|
			if node.is?(:mds)
				mds_nids << node.nid
			end
		}

		if @mds_nids != mds_nids
			@mds_nids = mds_nids
			ebus_signal(:mds_changed, mds_nids)
		end
	end

	def replset_info_changed(replset_info)
		@replset_info = replset_info
	end

	def get_replset_nids(rsid)
		unless @replset_info.include?(rsid)
			raise "Unknown replset id: #{rsid}"
		end
		info = @replset_info[rsid]
		## TODO
		#unless info.active?
		#	raise "Replset id #{rsid} is not active"
		#end
		info.nids
	end

	ebus_connect :get_mds_nids, :mds_nids
	ebus_connect :get_replset_nids
	ebus_connect :nodes_info_changed
	ebus_connect :replset_info_changed
end


end

