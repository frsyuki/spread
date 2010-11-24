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


class FileUpdateLog < UpdateLog
	# +---------+
	# | 
	# +---------+
	# start-timestamp
	#
	# time
	#    offset
	#        size
	#
	#
	# magic
	# first-time
	# index-region-size
	#   index-region
	#     record...
	#

	HEADER_SIZE = 64

	class LogFile
		def initialize(path)
			@path = path
			@file = File.open(@path, File::RDWR|File::CREAT)
			read_index
		end

		def close
			@file.close
		end

		def append(data, &block)
			data = data.to_s
			if data.empty?
				return nil
			end

			@file.pos = @tail
			@file.write VariableByteCode.encode(data.size)
			@file.write data

			block.call

			@index.push(@tail)
			@tail = @file.pos
		end

		def get(offset)
			pos = @index[offset]
			unless pos
				return nil, offset
			end

			@file.pos = pos
			rsize = VariableByteCode.decode_stream(@file)
			data = @file.read(rsize)

			return data, offset+1
		end

		private
		def read_index
			fsize = @file.stat.size
			if fsize < HEADER_SIZE
				init_file
				@index = []
				@tail = HEADER_SIZE
				return
			end

			pos = @file.pos = HEADER_SIZE
			index = []
			tail = pos
			while true
				rsize = VariableByteCode.decode_stream(@file)
				if rsize == 0
					break
				end
				vbsize = @file.pos - pos

				ntail = pos + vbsize + rsize
				#puts "vbsize: #{vbsize}"
				#puts "rsize: #{rsize}"
				#puts "ntail: #{ntail}"
				#puts "fsize: #{fsize}"
				if fsize < ntail
					break
				end

				index.push(pos)
				tail = ntail
				pos = @file.pos = ntail
			end

			@index = index
			@tail = tail

		rescue
			# FIXME
			$log.warn $!
			raise
		end

		def init_file
			@file.truncate(HEADER_SIZE)
		end
	end

	def initialize(path)
		@path = path
		# FIXME rotation
		@f = LogFile.new("#{path}/ulog-0000000001")
	end

	def close
		# FIXME rotation
		@f.close
	end

	def append(data, &block)
		# FIXME rotation
		@f.append(data, &block)
	end

	def get(offset)
		# FIXME rotation
		@f.get(offset)
	end
end


end
