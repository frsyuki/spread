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

class DirectoryStorageService < StorageService
	StorageSelector.register(:dir, self)

	def open(expr)
		@dir = expr
	end

	def close
	end

	def get(sid, key)
		read(sid, key, nil, nil)
	end

	def read(sid, key, offset, size)
		$log.trace { "DirectoryStorage: read sid=#{sid} key=#{key.dump} offset=#{offset} size=#{size}" }

		path = key_to_path(sid, key)
		begin
			return File.read(path, size, offset)
		rescue
			return nil
		end
	end

	def set(sid, key, data)
		$log.trace { "DirectoryStorage: set sid=#{sid} key=#{key.dump} data=#{data.size}byte)" }

		path = key_to_path(sid, key)
		make_dir(path)

		tmp_path = path+".tmp"
		File.open(tmp_path, File::WRONLY|File::CREAT|File::TRUNC) {|f|
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

	def write(sid, key, offset, data)
		$log.trace { "DirectoryStorage: write sid=#{sid} key=#{key.dump} offset=#{offset} data=#{data.size}bytes" }

		path = key_to_path(sid, key)
		make_dir(path)

		File.open(path, File::WRONLY|File::CREAT) {|f|
			f.pos = offset
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

		true
	end

	#def resize(sid, key, size)
	#	$log.trace { "DirectoryStorage: resize sid=#{sid} key=#{key.dump} size=#{size}" }
	#
	#	path = key_to_path(sid, key)
	#	make_dir(path)
	#
	#	File.open(path, File::WRONLY|File::CREAT) {|f|
	#		f.truncate(size)
	#	}
	#
	#	true
	#end

	def remove(sid, key)
		$log.trace { "DirectoryStorage: remove sid=#{sid} key=#{key.dump}" }

		path = key_to_path(sid, key)
		begin
			File.unlink(path)
			return true
		rescue
			return false
		end
	end

	def get_items
		num = 0
		Dir.glob("#{@dir}/sid-*") {|sdir|
			(0..0xff).each {|d|
				dir = "%03d" % d
				dirpath = File.join(sdir, dir)
				begin
					e = Dir.entries(dirpath).size
					e -= 2  # skip "." and ".."
					num += e if e > 0
				rescue
				end
			}
		}
		num
	end

	private
	def key_to_path(sid, key)
		sdir = "sid-%05d" % sid
		digest = Digest::MD5.digest(key)
		dir = "%03d" % digest.unpack('C')[0]
		fname = encode_path(key)
		File.join(@dir, sdir, dir, fname)
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
