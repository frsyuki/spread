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


class FaultInfo
	def initialize
		@nids = []
		update_hash
	end

	attr_reader :nids

	def add_nid(nid)
		if @nids.include?(nid)
			return nil
		end
		@nids << nid
		update_hash
		true
	end

	def add_nids(nids)
		added = []
		nids.each {|nid|
			unless @nids.include?(nid)
				added.push(nid)
				@nids.push(nid)
			end
		}
		if added.empty?
			return nil
		end
		update_hash
		return added
	end

	def remove_nid(nid)
		removed = @nids.delete(nid)
		update_hash
		removed ? true : nil
	end

	def include?(nid)
		@nids.include?(nid)
	end

	def get_hash
		@hash
	end

	def to_s
		"FaultInfo #{@nids.size} nodes nids=[\n" +
			"  #{@nids.join(", ")}\n" +
			"  ] hash=#{@hash.to_s.unpack('C*').map{|c|"%0x"%c}.join}"
	end

	private
	def update_hash
		@hash = Digest::SHA1.digest(to_msgpack)
		nil
	end

	public
	def to_msgpack(out = '')
		@nids.to_msgpack(out)
	end
	def from_msgpack(obj)
		@nids = obj
		update_hash
		self
	end
end


end

