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


require 'fileutils'
require 'uri'

class FileStorage < Storage
	def initialize(path)
		@path = path
	end

	def close
	end

	def get(key)
		$log.trace { "FileStorage: get(#{key.dump})" }  # FIXME

		path = key_to_path(key)
		begin
			return File.read(path)
		rescue
			return nil
		end
	end

	def set(key, data)
		$log.trace { "FileStorage: set(#{key.dump}, #{data.dump})" }  # FIXME

		path = key_to_path(key)
		make_dir(path)

		tmp_path = path+".tmp"
		File.open(tmp_path, 'w') {|f|
			#f.write(data)
			while true
				n = f.syswrite(data)
				if data.size <= n
					break
				else
					data = data[n..-1]
					#data.slice!(0,n-1)
				end
			end
		}

		File.rename(tmp_path, path)

		true
	end

	def remove(key)
		$log.trace { "FileStorage: remove(#{key.dump})" }  # FIXME

		path = key_to_path(key)
		begin
			File.unlink(path)
			return true
		rescue
			return false
		end
	end

	def get_items
		# FIXME
		num = 0
		(0..0xff).each {|d|
			dir = "%03d" % d
			dirpath = File.join(@path, dir)
			begin
				e = Dir.entries(dirpath).size
				e -= 2  # skip "." and ".."
				num += e if e > 0
			rescue
			end
		}
		num
	end

	private
	def key_to_path(key)
		digest = Digest::MD5.digest(key)
		dir = "%03d" % digest.unpack('C')[0]
		fname = encode_path(key)
		File.join(@path, dir, fname)
	end

	def encode_path(s)
		URI.encode(s, /[^-_.a-zA-Z0-9]/n)
	end

	def decode_path(b)
		URI.decode(b, /[^-_.a-zA-Z0-9]/n)
	end

	def make_dir(path)
		FileUtils.mkdir_p File.dirname(path)
	end
end


end
