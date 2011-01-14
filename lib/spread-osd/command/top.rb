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

begin
	require 'rubygems'
rescue LoadError
end
require 'msgpack/rpc'
require 'optparse'
require "curses"
require 'pp'

op = OptionParser.new
op.banner += " <cs address>"

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

if ARGV.length < 1
	usage(nil)
end

$net = MessagePack::RPC::SessionPool.new
addr = ARGV.shift
host, port = addr.split(':', 2)
port = port.to_i
port = 18700 if port == 0
$addr = [host,port]#Address.new(host, port)

begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

rescue
	usage $!.to_s
end


TITLES  = %w[nid name address replset #Read #Write Read/s Write/s QPS items time]
#FORMAT_SMALL = %[%1$22s%2$9s%3$9s%4$9s%9$10s %10$19s %12$8s\n                      %5$9s%6$9s%7$9s%8$10s %11$19s]
FORMAT_LARGE = %[%3s %15s %23s %8s %8s %8s %7s %7s %7s %10s %20s]
TIME_FORMAT = "%Y-%m-%d %H:%M:%S"


class TargetNode
	def initialize(nid, address, name, rsids)
		@nid = nid
		@address = address
		@name = name
		@rsids = rsids
		@time = Time.at(0)
		@before_read  = 0
		@before_write = 0
		@futures = []
	end

	def refresh_async
		s = $net.get_session(*@address)
		@futures = []
		@futures[0] = s.call_async(:stat, 'cmd_read')
		@futures[1] = s.call_async(:stat, 'cmd_write')
		@futures[2] = s.call_async(:stat, 'time')
		@futures[3] = s.call_async(:stat, 'db_items')

		now = Time.now
		@elapse = now - @time
		@time = now

		self
	end

	def refresh_async_get
		nread    = @futures[0].get
		nwrite   = @futures[1].get
		time     = @futures[2].get
		db_items = @futures[3].get
		psread   = (nread  - @before_read ) / @elapse
		pswrite  = (nwrite - @before_write) / @elapse
		@before_read  = nread
		@before_write = nwrite
		[
			@nid,
			@name,
			@address.to_s,
			@rsids.join(','),
			nread,
			nwrite,
			psread.to_i,
			pswrite.to_i,
			(psread + pswrite).to_i,
			db_items,
			time_format(time),
		]
	rescue
		[
			@nid,
			@address.to_s,
			@name,
			@rsids.join(','),
			$!.to_s,
		]
	end

	def time_format(t)
		if t
			Time.at(t).strftime(TIME_FORMAT)
		else
			""
		end
	end
end


s = $net.get_session(*$addr)
s.timeout = 20
nodes = s.call(:stat, 'nodes').map {|nid,address,name,rsids|
	address = MessagePack::RPC::Address.load(address)
	TargetNode.new(nid, address, name, rsids)
}


def refresh(nodes)
	Curses.clear
	#if Curses.stdscr.maxx - 1 >= 129
		format = FORMAT_LARGE
	#else
	#	format = FORMAT_SMALL
	#end

	Curses.setpos(0, 0)
	title_line = format % TITLES
	nlines = title_line.count("\n")+1
	Curses.addstr(title_line)

	nodes.each {|node|
		node.refresh_async
	}
	nodes.each_with_index {|node, i|
		Curses.setpos((1+i)*nlines, 0)
		params = node.refresh_async_get
		line = format % params
		Curses.addstr(line)
	}

	Curses.refresh
end

def curses_thread(nodes)
	while true
		before = Time.now

		refresh(nodes)

		elapse = Time.now - before
		if elapse < 0.5
			sleep 0.5 - elapse
		end
	end
rescue
	$stderr.puts $!.inspect
end


Curses.init_screen

begin
	th = Thread.start(nodes, &method(:curses_thread))

	while true
		ch = Curses.getch
		if ch == ?q
			break
		else
			#refresh(nodes)
		end
	end

ensure
	Curses.close_screen
end

