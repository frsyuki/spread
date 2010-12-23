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


class MDSService < Service
	def initialize
		super
		@addrs = nil
		@mds = nil
	end

	def open_blocking(cs_addr)
		addrs = ebus_call(:get_session, cs_addr).call(:get_mds)
		reopen(addrs)
	end

	def run
		ebus_call(:config_sync_register, CONFIG_SYNC_MDS_ADDRESS,
							get_hash) do |obj|
			reopen(obj)
			get_hash
		end
	end

	def shutdown
		@mds.close if @mds
	end

	def mds_get(key, &block)
		@mds.get(key, &block)
	end

	def mds_set(key, map, &block)
		@mds.set(key, map, &block)
	end

	def mds_remove(key, &block)
		@mds.remove(key, &block)
	end

	#def mds_add_or_get(key, map, &block)
	#	@mds.add_or_get(key, map, &block)
	#end

	ebus_connect :run
	ebus_connect :shutdown
	ebus_connect :mds_get
	ebus_connect :mds_set
	ebus_connect :mds_remove
	#ebus_connect :mds_add_or_get

	private
	def reopen(new_addrs)
		new_mds = MDS.open(new_addrs)
		@mds.close if @mds
		@mds = new_mds
		@addrs = new_addrs
		update_hash
	end

	def get_hash
		@addrs_hash
	end

	def update_hash
		@addrs_hash = Digest::SHA1.digest(@addrs)
	end
end


end
