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


class MetadataClientService < Service
	def initialize
		super()
		@confsvr = ebus_call(:get_confsvr_address)
	end

	def add_key(key_seq, attributes, &block)
		mds_session.callback(:add_key, key_seq, attributes) do |future|
			block.call(future.result, future.error)
		end
	end

	def get_key(key_seq, &block)
		mds_session.callback(:get_key, key_seq) do |future|
			block.call(future.result, future.error)
		end
	end

	def get_child_keys(key_seq, skip, limit, &block)
		mds_session.callback(:get_child_keys, key_seq, skip, limit) do |future|
			block.call(future.result, future.error)
		end
	end

	def set_attributes(key_seq, attributes, &block)
		mds_session.callback(:set_attributes, key_seq, attributes) do |future|
			block.call(future.result, future.error)
		end
	end

	def remove_key(key_seq, &block)
		mds_session.callback(:remove_key, key_seq) do |future|
			block.call(future.result, future.error)
		end
	end

	private
	def mds_session
		#nid = @mds_nids.first
		#unless nid
		#	raise "mds is not ready"
		#end
		#node = ebus_call(:get_node, nid)
		#node.session
		$net.get_session(@confsvr)
	end

	ebus_connect :metadata_add_key, :add_key
	ebus_connect :metadata_get_key, :get_key
	ebus_connect :metadata_get_child_keys, :get_child_keys
	ebus_connect :metadata_set_attributes, :set_attributes
	ebus_connect :metadata_remove_key, :remove_key
end


end

