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


class UpdateLogBus < Bus
	call_slot :open
	call_slot :close

	call_slot :append

	call_slot :get
end


class UpdateLogSelector
	IMPLS = {}

	def self.register(name, klass)
		IMPLS[name.to_sym] = klass
		nil
	end

	def self.select_class(uri)
		uri ||= "mem:"

		if m = /^(\w{1,8})\:(.*)/.match(uri)
			type = m[1].to_sym
			expr = m[2]
		else
			type = :file
			expr = uri
		end

		klass = IMPLS[type]

		unless klass
			"unknown UpdateLog type: #{type}"
		end

		return klass, expr
	end

	def self.select!(uri)
		klass, expr = select_class(uri)
		klass.init

		UpdateLogBus.open(expr)
	end

	def self.open!
		select!(ConfigBus.get_ulog_path)
	end
end


class UpdateLogService < Service
	#def open(expr)
	#end

	#def close
	#end

	#def append(data, &block)
	#end

	#def get(pos)
	#end

	ebus_connect :UpdateLogBus,
		:append,
		:get,
		:open,
		:close

	def shutdown
		UpdateLogBus.close
	end

	ebus_connect :ProcessBus,
		:shutdown
end


# +-+------+--...---+
# |1|vbcode|  raw   |
# +-+------+--...---+
# 0x91
#   sid
#          key
#
# +-+------+------+------+--...---+
# |1|vbcode|vbcode|vbcode|  raw   |
# +-+------+------+------+--...---+
# 0x93
#   sid
#          offset
#                 size
#                        key
#
class UpdateLogData
	def initialize(sid, key, *meta)
		@sid = sid
		@key = key
		@meta = meta
	end

	attr_reader :sid
	attr_reader :key
	attr_reader :meta

	def offset
		@meta[0]
	end

	def size
		@meta[1]
	end

	def dump
		raw = [0x91 + @meta.size].pack('C')
		VariableByteCode.encode(@sid, raw)
		meta.each {|m|
			VariableByteCode.encode(m, raw)
		}
		raw << key
		raw
	end

	def self.load(raw)
		n = raw.unpack('C')[0]
		sid, i = VariableByteCode.decode_index(raw, 1)
		meta = []
		(n - 0x91).times {
			m, i = VariableByteCode.decode_index(raw, i)
			meta << m
		}
		key = raw[i..-1]
		new(sid, key, *meta)
	end
end


end
