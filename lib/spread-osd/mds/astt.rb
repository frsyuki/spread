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


# FIXME SO_SNDTIMEO

class AsyncTokyoTyrantSocket < Rev::TCPSocket
	def initialize(io, loop, addr, servers)
		super(io)
		@time = Time.now.to_f
		@addr = addr
		@servers = servers
		@connected = false
		@queue = []
		@buffer = ''
		@reqlen = 0
		@state = nil
		@loop = loop
	end

	def touch(time)
		@time = time
	end
	attr_reader :time

	def close
		@loop.detach(self) rescue nil
		@queue.reject! {|state|
			state.failed
			true
		}
		super rescue nil
	end

	def on_connect
		@connected = true
	end

	def on_connect_failed
		close rescue nil
	end

	def connected?
		@connected
	end

	def on_readable
		super
	rescue
		close
	end

	def on_read(data)
		if @queue.empty?
			close
			return
		end

		@buffer << data

		if @state
			@state = @state.call(@buffer)
		else
			@state = @queue[0].call(@buffer)
		end

		if @state == nil
			@queue.shift
		end
	end

	class State
		def initialize(callback)
			@callback = callback
		end

		def call(buffer)
			if buffer.length < 1
				return self
			end
			code = buffer.slice!(0,1).unpack('C')[0]
			on_code(code, buffer)
		end

		def result(data)
			if @callback
				@callback.call(data) rescue nil
				@callback = nil
			end
		end

		def failed
			result(nil)
		end
	end

	class GetState < State
		def on_code(code, buffer)
			if code != 0
				result(nil)
				return nil
			end
			on_vsiz(buffer)
		end

		def on_vsiz(buffer)
			if buffer.length < 4
				return method(:on_vsiz)
			end
			@vsiz = buffer.slice!(0,4).unpack('N')[0]
			on_vbuf(buffer)
		end

		def on_vbuf(buffer)
			if buffer.length < @vsiz
				return method(:on_vbuf)
			end
			vbuf = buffer.slice!(0,@vsiz)
			result(vbuf)
			return nil
		end
	end

	class PutState < State
		def on_code(code, buffer)
			result(code == 0)
			return nil
		end
	end

	class OutState < State
		def on_code(code, buffer)
			result(code == 0)
			return nil
		end
	end

	def send_get(callback, key)
		write [0xC8, 0x30, key.size].pack('CCN')
		write key
		@queue.push GetState.new(callback)
		nil
	end

	def send_put(callback, key, val)
		write [0xC8, 0x10, key.size, val.size].pack('CCNN')
		write key
		write val
		@queue.push PutState.new(callback)
		nil
	end

	def send_out(callback, key)
		write [0xC8, 0x20, key.size].pack('CCN')
		write key
		@queue.push OutState.new(callback)
		nil
	end
end

class AsyncTokyoTyrant
	def initialize(loop, timeout)
		@servers = []  # [stream]
		@rr = 0
		@ck = ConnectionKeeper.new(@servers, timeout)
		loop.attach(@ck)
		@loop = loop
	end

	def close
		@ck.detach rescue nil
		@servers.reject! {|s|
			s.close rescue nil
			true
		}
	end

	class ConnectionKeeper < Rev::TimerWatcher
		def initialize(servers, timeout)
			super(1.0, true)
			@timeout = timeout
			@servers = servers
		end
		def on_timer
			now = Time.now.to_f
			@servers.each {|s|
				if s.closed?
					#
				elsif s.connected?
					s.touch(now)
				elsif now - s.time > @timeout
					s.close rescue nil
				else
					#
				end
			}
		end
	end

	def add_server(host, port)
		addr = MessagePack::RPC::Address.new(host, port)
		if s = @servers.find {|s| s.addr == addr }
			s.close rescue nil
		end
		s = AsyncTokyoTyrantSocket.connect(addr.host, addr.port, @loop, addr, @servers)
		@servers << s
		@loop.attach(s)
	end

	attr_reader :servers

	def get(key, &block)
		choice_server.send_get(block, key)
		nil
	rescue
		block.call(nil)
	end

	def put(key, val, &block)
		choice_server.send_put(block, key, val)
		nil
	rescue
		block.call(false)
	end

	def out(key, &block)
		choice_server.send_out(block, key)
		nil
	rescue
		block.call(false)
	end

	private
	def choice_server
		if @servers.empty?
			raise "no Tokyo Tyrant servers are registered"
		end

		@rr = (@rr+1) % @servers.size

		@servers.size.times {|i|
			idx = (@rr+i) % @servers.size
			s = @servers[idx]
			if s.closed?
				#
			elsif s.connected?
				return s
			elsif s.closed?
				addr = s.addr
				s = AsyncTokyoTyrantSocket.connect(addr.host, addr.port, @loop, addr, @servers)
				@servers[idx] = s
				@loop.attach(s)
			else
				#
			end
		}

		raise "all Tokyo Tyrant servers are down"
	end
end


class AsyncTokyoTyrantMDS < MDS
	DEFAULT_PORT = 1978

	def initialize(addrs, timeout = 30.0)
		loop = $net.loop
		@ast = AsyncTokyoTyrant.new(loop, timeout)
		addrs.split(/\s*,\s*/).each {|addr|
			host, port = addrs.strip.split(':',2)
			port ||= DEFAULT_PORT
			@ast.add_server(host, port)
		}
	end

	def close
		@ast.close
	end

	def get(key, &block)
		@ast.get(key) {|vbuf|
			if vbuf
				map = Hash[*vbuf.split("\0")]
			else
				map = {}
			end
			block.call(map)
		}
		nil
	end

	def set(key, map, &block)
		vbuf = map.to_a.flatten.join("\0")
		@ast.put(key, vbuf, &block)
		nil
	end

	def remove(key, &block)
		@ast.get(key) {|vbuf|
			if vbuf
				map = Hash[vbuf.split("\0")]
				@ast.out(key) {|success|
					block.call(map)
				}
			else
				block.call({})
			end
		}
		nil
	end
end


end

