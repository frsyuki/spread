#!/usr/bin/env ruby

require 'spread'

include SpreadOSD

if ARGV.length != 2
	puts "usage: #{File.basename($0)} <address:port> <file>"
	exit 1
end

addr = ARGV.shift
host, port = addr.split(':', 2)
addr = Address.new(host, port)

path = ARGV.shift
data = File.read(path)

LOOP = 1
DEPTH = 4
NUM= LOOP * DEPTH
SIZE = data.size*NUM


start = Time.now

s = $net.get_session(addr)
LOOP.times do |lp|
	(1..DEPTH).to_a.map {|i|
		key = "k#{i}"
		s.call_async(:add, [key], {}, data)
	}.map {|f|
		f.get
	}
end

finish = Time.now

sec = finish - start
bps = SIZE / sec * 8

puts "set:"
puts "  #{sec} sec."
puts "  #{bps/1000/1000} Mbps"


start = Time.now

s = $net.get_session(addr)
LOOP.times do |lp|
	(1..DEPTH).to_a.map {|i|
		key = "k#{i}"
		s.call_async(:get, [key])
	}.map {|f|
		f.get
	}
end

finish = Time.now

sec = finish - start
bps = SIZE / sec * 8

puts "get:"
puts "  #{sec} sec."
puts "  #{bps/1000/1000} Mbps"

