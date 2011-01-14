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


class TSVData
	def initialize
		update_hash
	end

	def get_hash
		@hash
	end

	def open(path)
		@path = path
		read
	end

	def close
	end

	protected
	def on_change
		update_hash
		write
	end

	def update_hash
		@hash = Digest::SHA1.digest(to_msgpack)
		write
	end

	if RUBY_VERSION >= "1.9"
		def tsv_read(path=@path, &block)
			CSV.open(path, "r", :col_sep => "\t") do |csv|
				csv.each {|row|
					yield row
				}
			end
		end
		def tsv_write(path=@path, &block)
			tmp_path = "#{path}.tmp"
			CSV.open(tmp_path, "w", :col_sep => "\t") do |csv|
				yield csv
			end
			File.rename(tmp_path, path)
		end
	else
		def tsv_read(path=@path, &block)
			CSV.open(path, "r", "\t") do |row|
				yield row
			end
		end
		def tsv_write(path=@path, &block)
			tmp_path = "#{path}.tmp"
			CSV.open(tmp_path, "w", "\t") do |writer|
				yield writer
			end
			File.rename(tmp_path, path)
		end
	end
end


end
