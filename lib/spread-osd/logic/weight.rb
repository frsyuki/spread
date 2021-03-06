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


class WeightInfo
	DEFAULT_WEIGHT = 10

	def initialize
		@map = {}  # {rsid => weight}
		update_hash
	end

	def open(path)
		@path = path
		read
	end

	def close
	end

	def set_weight(rsid, weight)
		if @map[rsid] == weight
			return nil
		end
		@map[rsid] = weight
		on_change
		true
	end

	def reset_weight(rsid)
		unless @map.delete(rsid)
			return nil
		end
		on_change
		true
	end

	def set_defaults(rsids)
		#@map.reject! {|rsid,weight|
		#	!rsids.include?(rsid)
		#}
		rsids.each {|rsid|
			@map[rsid] ||= DEFAULT_WEIGHT
		}
		on_change
		true
	end

	def get_weight(rsid)
		@map[rsid] || DEFAULT_WEIGHT
	end

	def get_registered_rsids
		@map.keys
	end

	def get_registered_weights
		@map.dup
	end

	def get_all_with_default(rsids)
		result = {}
		rsids.each {|rsid|
			result[rsid] = @map[rsid] || DEFAULT_WEIGHT
		}
		result
	end

	def get_hash
		@hash
	end

	def to_msgpack(out = '')
		@map.to_msgpack(out)
	end

	def from_msgpack(obj)
		@map = obj
		on_change
		self
	end

	private
	def read
		return nil unless @path
		# FIXME
	end

	def write
		return nil unless @path
		# FIXME
	end

	def on_change
		update_hash
		write
	end

	def update_hash
		@hash = Digest::SHA1.digest(to_msgpack)
	end
end


=begin
class WeightBalancer < WeightInfo
	def initialize
		super
		@array = []
		@rsids = []
		@rr = 0
		calc
	end

	def set_rsids(rsids)
		@rsids = rsids
		calc
		nil
	end

	def select_next_rsid
		if @array.empty?
			raise "no replication set is registered"
		end
		@rr += 1
		@rr = 0 if @rr >= @array.size
		@array[@rr]
	end

	private
	def on_change
		super
		calc
	end

	def calc
		array = []
		@rsids.each {|rsid|
			weight = @map[rsid] || DEFAULT_WEIGHT
			weight.times {
				array << rsid
			}
		}
		@array = array.shuffle
	end
end
=end


end
