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


class FaultList
	def initialize
		@path = nil
		@fault_nids = []
		update_hash
	end

	def update(nids)
		@fault_nids = nids.dup
		on_change
		nil
	end

	def include?(nid)
		@fault_nids.include?(nid)
	end

	def get_hash
		@hash
	end

	def get_list
		@fault_nids.dup
	end

	def to_msgpack(out = '')
		@fault_nids.to_msgpack(out)
	end

	def from_msgpack(msg)
		@fault_nids = msg
		on_change
		self
	end

	def open(path)
		@path = path
		read
	end

	def close
		# FIXME
	end

	private
	def read
		return unless @path

		begin
			fault_nids = []

			tsv_read(@path) do |row|
				fault_nids << row[0].to_i
			end

			p fault_nids
			@fault_nids = fault_nids

		rescue
			$log.debug $!
		end

		update_hash
	end

	def write
		return unless @path

		tmp_path = "#{@path}.tmp"

		tsv_write(tmp_path) do |writer|
			@fault_nids.each {|nid|
				writer << [nid.to_s]
			}
		end

		File.rename(tmp_path, @path)
	end

	def on_change
		update_hash
		write
	end

	def update_hash
		@hash = Digest::SHA1.digest(to_msgpack)
	end


	if RUBY_VERSION >= "1.9"
		def tsv_read(path, &block)
			CSV.open(path, "r", :col_sep => "\t") do |csv|
				csv.each {|row|
					yield row
				}
			end
		end
		def tsv_write(path, &block)
			CSV.open(path, "w", :col_sep => "\t") do |csv|
				yield csv
			end
		end
	else
		def tsv_read(path, &block)
			CSV.open(path, "r", "\t") do |row|
				yield row
			end
		end
		def tsv_write(path, &block)
			CSV.open(path, "w", "\t") do |writer|
				yield writer
			end
		end
	end
end


class FaultDetector
	class Term
		def initialize(value)
			@value = value
		end
		def expired?
			@value <= 0
		end
		def forward_timer
			if @value > 0
				@value -= 1
				if @value == 0
					return true
				end
				return false
			end
			return nil
		end
		def reset(value)
			@value = value
		end
		attr_accessor :value
	end

	def initialize
		@period = 10
		@detect = 5
		@first_detect = 600
		@map = {}  # {nid => Term}
	end

	def set_init(all_nids, fault_nids)
		map = {}
		all_nids.each {|nid|
			map[nid] = Term.new(@period + @first_detect)
		}
		fault_nids.each {|nid|
			if all_nids.include?(nid)
				map[nid] = Term.new(0)
			end
		}
		@map = map
		nil
	end

	def update(nid)
		term = @map[nid]
		if term && !term.expired?
			term.reset(@period + @detect)
			return @period
		end
		return nil
	end

	def reset(nid)
		if term = @map[nid]
			term.reset(@period + @detect)
			on_change
			return true
		end
		return nil
	end

	def add_nid(nid)
		if term = @map[nid]
			return nil
		end
		@map[nid] = Term.new(@period + @first_detect)
		return true
	end

	def set_nid(nid)
		if @map.has_key?(nid)
			reset(nid)
		else
			add_nid(nid)
		end
	end

	def delete_nid(nid)
		if term = @map.delete(nid)
			if term.expired?
				on_change
			end
			return true
		end
		return nil
	end

	def get_fault_nids
		fault_nids = []
		@map.each_pair {|nid,term|
			if term.expired?
				fault_nids << nid
			end
		}
		fault_nids
	end

	def forward_timer
		fault_nids = []
		@map.each_pair {|nid,term|
			if term.forward_timer
				fault_nids << nid
			end
		}

		if !fault_nids.empty?
			on_change
		end

		fault_nids
	end

	private
	def on_change
		# do nothing
	end
end


end
