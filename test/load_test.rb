#!/usr/bin/env ruby

begin
	require 'rubygems'
rescue LoadError
end
require 'chukan'
require 'msgpack/rpc'

include Chukan::Test

host = '127.0.0.1'
port = ARGV[0] || 18800

THREAD = 1
LOOP = 2
SIZE = 4*1024*1024
NUM  = 100
DUP  = 3

pid = Process.pid

data = " " * SIZE

threads = (1..THREAD).map do

	test "remove existent keys" do
		c = MessagePack::RPC::Client.new(host, port)
		(NUM/DUP*DUP).times {|i|
			c.call(:remove, "k#{i}")
		}
	end

	Thread.new(MessagePack::RPC::Client.new(host, port)) {|c|

		test "run normally" do
			LOOP.times {
				puts "set #{SIZE} bytes #{NUM/DUP*DUP} items with #{DUP} async"
				t = Time.now
				(NUM/DUP).times {|n|
					ar = []
					DUP.times {|d|
						#f = c.call_async(:add, "k#{n*DUP+d}", data, {"attr"=>"at"})
						f = c.call_async(:add_data, "k#{pid}-#{n*DUP+d}", data)
						ar << f
					}
					ar.each {|f|
						f.get
					}
				}
				e = Time.now - t
				puts "#{e} sec."
				puts "#{NUM/DUP*DUP/e} req/sec"
				puts "#{NUM/DUP*DUP/e*SIZE/1024/1024} MB/sec"

				puts "get #{SIZE} bytes #{NUM/DUP*DUP} items with #{DUP} async"
				t = Time.now
				(NUM/DUP).times {|n|
					ar = []
					DUP.times {|d|
						f = c.call_async(:get, "k#{pid}-#{n*DUP+d}")
						ar << f
					}
					ar.each {|f|
						f.get
					}
				}
				e = Time.now - t
				puts "#{e} sec."
				puts "#{NUM/DUP*DUP/e} req/sec"
				puts "#{NUM/DUP*DUP/e*SIZE/1024/1024} MB/sec"
			}
		end

	}
end.each {|th|
	th.join
}

