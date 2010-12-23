#
# VariableByteCode
#
# Copyright (C) 2010 FURUHASHI Sadayuki. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

class VariableByteCode
	if "a"[0].is_a?(String)  # ruby 1.9
		def self.encode(value, raw="")
			begin
				v = value & 0b01111111 | 0b10000000
				value >>= 7
				raw << [v].pack('C')
			end while value > 0
			raw[raw.length-1] = [raw[raw.length-1].unpack('C')[0] & 0b01111111].pack('C')
			raw
		end
	else
		def self.encode(value, raw="")
			begin
				v = value & 0b01111111 | 0b10000000
				value >>= 7
				raw << [v].pack('C')
			end while value > 0
			raw[raw.length-1] &= 0b01111111
			raw
		end
	end


	if "a"[0].is_a?(String)  # ruby 1.9
		def self.decode(raw)
			i = 0
			value = 0
			while raw.length > i
				v = raw[i].unpack('C')[0]
				if v & 0b10000000 != 0
					v &= 0b01111111
					v <<= (i*7)
					value |= v
				else
					v <<= (i*7)
					value |= v
					return value
				end
				i += 1
			end
			return value
		end
	else
		def self.decode(raw)
			i = 0
			value = 0
			while raw.length > i
				v = raw[i]
				if v & 0b10000000 != 0
					v &= 0b01111111
					v <<= (i*7)
					value |= v
				else
					v <<= (i*7)
					value |= v
					return value
				end
				i += 1
			end
			return value
		end
	end


	if "a"[0].is_a?(String)  # ruby 1.9
		def self.decode_index(raw, from=0)
			i = from
			value = 0
			while raw.length > i
				v = raw[i].unpack('C')[0]
				if v & 0b10000000 != 0
					v &= 0b01111111
					v <<= ((i-from)*7)
					value |= v
				else
					v <<= ((i-from)*7)
					value |= v
					return value, i+1
				end
				i += 1
			end
			return value, i
		end
	else
		def self.decode_index(raw, from=0)
			i = from
			value = 0
			while raw.length > i
				v = raw[i]
				if v & 0b10000000 != 0
					v &= 0b01111111
					v <<= ((i-from)*7)
					value |= v
				else
					v <<= ((i-from)*7)
					value |= v
					return value, i+1
				end
				i += 1
			end
			return value, i
		end
	end


	if "a"[0].is_a?(String)  # ruby 1.9
		def self.decode_stream(io)
			i = 0
			value = 0
			b = " "
			while b = io.read(1, b)
				v = b.unpack('C')[0]
				if v & 0b10000000 != 0
					v &= 0b01111111
					v <<= (i*7)
					value |= v
				else
					v <<= (i*7)
					value |= v
					return value
				end
				i += 1
			end
			return value
		end
	else
		def self.decode_stream(io)
			i = 0
			value = 0
			b = " "
			while b = io.read(1, b)
				v = b[0]
				if v & 0b10000000 != 0
					v &= 0b01111111
					v <<= (i*7)
					value |= v
				else
					v <<= (i*7)
					value |= v
					return value
				end
				i += 1
			end
			return value
		end
	end


	def self.encode_n(array, out="")
		array.each {|value|
			encode(value, out)
		}
		out
	end


	def self.decode_n(raw, from=0, length=raw.length-from)
		upto = from + length
		upto = raw.length if upto > raw.length
		values = []
		while upto > from
			value, from = decode_index(raw, from)
			values << value
		end
		values
	end
end


if $0 == __FILE__
	puts "testing VariableByteCode ..."

	def check(value)
		raw = VariableByteCode.encode(value)
		if VariableByteCode.decode(raw) != value
			puts "VariableByteCode.decode test failed #{value}"
		end
		if VariableByteCode.decode_index(raw,0)[0] != value
			puts "VariableByteCode.decode_index test failed #{value}"
		end
	end

	100000.times {
		check rand(1<<64)
	}

	def check_n(values)
		raw = VariableByteCode.encode_n(values)
		if VariableByteCode.decode_n(raw) != values
			puts "VariableByteCode.decode_n test failed #{values}"
		end
	end

	100.times {
		check_n (1..rand(1<<8)).map {|i| rand(1<<64) }
	}
end

