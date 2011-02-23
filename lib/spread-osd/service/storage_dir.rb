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
		@dir = File.expand_path(expr)
	end

	def close
	end

	def get(vtime, key)
		read(vtime, key, nil, nil)
	end

	def read(vtime, key, offset, size)
		$log.trace { "DirectoryStorage: read vtime=#{vtime} key=#{key.dump} offset=#{offset} size=#{size}" }

		path = key_to_path(vtime, key)
		begin
			return File.read(path, size, offset)
		rescue
			return nil
		end
	end

	def set(vtime, key, data)
		$log.trace { "DirectoryStorage: set vtime=#{vtime} key=#{key.dump} data=#{data.size}byte)" }

		path = key_to_path(vtime, key)
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

	#def write(vtime, key, offset, data)
	#	$log.trace { "DirectoryStorage: write vtime=#{vtime} key=#{key.dump} offset=#{offset} data=#{data.size}bytes" }
	#
	#	path = key_to_path(vtime, key)
	#	make_dir(path)
	#
	#	File.open(path, File::WRONLY|File::CREAT) {|f|
	#		f.pos = offset
	#		#f.write(data)
	#		while true
	#			n = f.syswrite(data)
	#			if data.size <= n
	#				break
	#			else
	#				data = data[n..-1]
	#				#data.slice!(0,n-1)
	#			end
	#		end
	#	}
	#
	#	true
	#end

	#def append(vtime, key, data)
	#	$log.trace { "DirectoryStorage: append vtime=#{vtime} key=#{key.dump} offset=#{offset} data=#{data.size}bytes" }
	#
	#	path = key_to_path(vtime, key)
	#	make_dir(path)
	#
	#	size = nil
	#	File.open(path, File::WRONLY|File::CREAT|File::APPEND) {|f|
	#		#f.write(data)
	#		while true
	#			n = f.syswrite(data)
	#			if data.size <= n
	#				break
	#			else
	#				data = data[n..-1]
	#				#data.slice!(0,n-1)
	#			end
	#		end
	#		size = f.stat.size
	#	}
	#
	#	size
	#end

	#def resize(vtime, key, size)
	#	$log.trace { "DirectoryStorage: resize vtime=#{vtime} key=#{key.dump} size=#{size}" }
	#
	#	path = key_to_path(vtime, key)
	#	make_dir(path)
	#
	#	File.open(path, File::WRONLY|File::CREAT) {|f|
	#		f.truncate(size)
	#	}
	#
	#	true
	#end

	def delete(vtime, key)
		$log.trace { "DirectoryStorage: delete vtime=#{vtime} key=#{key.dump}" }

		path = key_to_path(vtime, key)
		begin
			File.unlink(path)
			Dir.rmdir(File.dirname(path)) rescue nil
			return true
		rescue
			return false
		end
	end

	def exist(vtime, key)
		$log.trace { "DirectoryStorage: exist vtime=#{vtime} key=#{key.dump}" }

		path = key_to_path(vtime, key)
		return File.exist?(path)
	end

	def get_items
		num = 0
		(0..0xff).each {|d|
			box = "%03d" % d
			dirpath = File.join(@dir, "data", box)
			begin
				e = Dir.entries(dirpath).size
				e -= 2  # skip "." and ".."
				num += e if e > 0
			rescue
			end
		}
		num
	end

	# for DataServerURLService
	def self.encode_okey(okey)
		subpath = key_to_subpath(okey.vtime, okey.key)
		File.join(*subpath)
	end

	def key_to_path(vtime, key)
		subpath = self.class.key_to_subpath(vtime, key)
		File.join(@dir, "data", *subpath)
	end

	def self.key_to_subpath(vtime, key)
		digest = Digest::MD5.digest(key)
		box = "%03d" % digest.unpack('C')[0]
		kdir = encode_path(key)
		fname = "v#{vtime}"
		return box, kdir, fname
	end

	private
	def self.encode_path(s)
		URI.encode(s, /[^-_.a-zA-Z0-9]/n)
	end

	def self.decode_path(b)
		URI.decode(b, /[^-_.a-zA-Z0-9]/n)
	end

	def make_dir(path)
		FileUtils.mkdir_p File.dirname(path)
	end
end


end
