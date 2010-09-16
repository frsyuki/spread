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


class LogStorage
	class Key
		def initialize(sidx, offset, size)
			@sidx = sidx       # 8ビット
			@offset = offset   # 64ビット
			@size = size       # 48ビット
		end

		attr_reader :sidx
		attr_reader :offset
		attr_reader :size

		# +-+-------+--------+
		# |8|  48   |   64   |
		# +-+-------+--------+
		# sidx
		#   size
		#           offset
		def dump
			upper64 = (@sidx<<56) | @size
			[upper64>>32, upper64&0xffffffff, @offset>>32, @offset&0xffffffff].pack('NNNN')
		end

		def self.load(raw)
			upper64_u, upper64_d, offset_u, offset_d = raw.unpack('NNNN')
			upper64 = (upper64_u<<32) | upper64_d
			sidx = upper64 >> 56
			size = upper64 & 0x00ffffff_ffffffff
			offset= (offset_u<<32) | offset_d
			self.new(sidx, offset, size)
		end
	end

	def initialize
		@dir_path = nil
		@prefix = nil
		@last_sidx = 0   # TODO 複数ファイル用:未使用
		@last_seqid = 0
		@last_offset = 0
	end

	attr_reader :last_sidx
	attr_reader :last_offset

	def open(dir_path, prefix)
		@dir_path = dir_path
		@prefix = prefix
		open_stream(0)
		nil
	end

	def close
		@last_file.close
		@dir_path = nil
	end

	def append(data, &block)
		# locked
		seqid = @last_seqid
		msg = [seqid, data]

		sidx = @last_sidx
		offset = @last_offset
		size = append_data(msg)

		key = Key.new(sidx, offset, size)
		block.call(key)

		update_header(offset+size, seqid+1)

		nil
	end

	def read(key)
		raw = read_range(@last_file, key.offset, key.size)
		seqid, data = MessagePack.unpack(raw)
		return data
	end

	def read_multi(sidx, offset, limit)
	end

	private
	def open_stream(sidx)
		path = "#{@dir_path}/#{@prefix}.#{sidx}.mpac"
		file = File.open(path, File::RDWR | File::CREAT)
		stat = file.stat
		if stat.size < MIN_STREAM_SIZE
			file.truncate(MIN_STREAM_SIZE)
			update_header(HEADER_SIZE, 1, file)
		else
			@last_offset, @last_seqid = read_header(file)
			if @last_offset < HEADER_SIZE || @last_seqid <= 0 || stat.size < @last_offset
				update_header(HEADER_SIZE, 1, file)
			end
		end
		@last_sidx = sidx
		@last_file = file
		return true
	end

	def append_data(msg)
		pos = @last_file.pos = @last_offset
		msg.to_msgpack(@last_file)
		#@last_file.write(msg.to_msgpack)
		#@last_file.flush  # TODO
		@last_file.pos - pos
	end

	def update_header(noffset, nseqid, file = @last_file)
		header = pack_header(noffset, nseqid)

		file.pos = 0
		file.syswrite(header)  # FIXME

		@last_offset = noffset
		@last_seqid = nseqid
	end

	def read_header(file)
		raw = file.read(HEADER_SIZE)
		unpack_header(raw)
	end

	def read_range(file, offset, size)
		file.pos = offset
		file.read(size)
	end

	## TODO
	#def read_one(file, offset)
	#	file.pos = offset
	#	MessagePack::Unpacker.new
	#	u.next
	#end

	HEADER_SIZE = 16
	MIN_STREAM_SIZE = 32*1024*1024

	# +--------+--------+
	# |   64   |   64   |
	# +--------+--------+
	# seqid
	#           offset
	def pack_header(offset, seqid)
		[seqid>>32, seqid&0xffffffff, offset>>32, offset&0xffffffff].pack('NNNN')
	end

	def unpack_header(raw)
		seqid_u, seqid_d, offset_u, offset_d = raw.unpack('NNNN')
		seqid = (seqid_u<<32) | seqid_d
		offset = (offset_u<<32) | offset_d
		return offset, seqid
	end
end


end


if $0 == __FILE__
	require 'rubygems'
	require 'msgpack'

	include SpreadOSD

	def check(ls, data)
		key = nil
		ls.append(data) do |k|
			puts "put sidx=#{k.sidx} offset=#{k.offset} size=#{k.size} data=#{data.dump}"
			key = k
		end
		rdata = ls.read(key)
		puts "read #{rdata.dump}"
		if data != rdata
			raise "written data and read data don't match!"
		end
	end

	dir_path = "log_storage_test"
	prefix = "stream"
	unless File.directory?(dir_path)
		Dir.mkdir(dir_path)
	end
	ls = LogStorage.new

	1000.times do
		ls.open(dir_path, prefix)
		check(ls, "hello")
		check(ls, "world!")
		ls.close
	end
end

