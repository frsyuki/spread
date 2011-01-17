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
cs_addr = [host,port]#Address.new(host, port)

begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

rescue
	usage $!.to_s
end


TITLES =
#      1    2       3        4       5     6      7      8       9  10    11   12
	%w[nid name address location replset #Read #Write Read/s Write/s QPS items time]

FORMAT_LARGE =
	%[%1$3s %2$12s %3$23s %4$23s %5$8s %6$8s %7$8s %8$7s %9$7s %10$7s %11$10s %12$20s]

FORMAT_LARGE_SIMPLE =
	%[%1$3s %2$12s%4$22s %5$8s %8$7s %9$7s %10$7s %11$10s]


FORMAT_SMALL =
#       1    2       5    6    7    11     4
	%[%1$3s%2$13s  %5$7s%6$9s%7$9s%11$9s%4$21s] +
	%[\n  %3$23s%8$9s%9$9s%10$9s%12$21s]
#            3    8    9   10      12

FORMAT_SMALL_SIMPLE =
#       1    2       5    6    7    11     4
	%[%1$3s%2$13s  %5$7s%6$9s%7$9s%11$9s%4$21s] +
	%[\n                         %8$9s%9$9s%10$9s]
#                                  8    9   10

TIME_FORMAT = "%Y-%m-%d %H:%M:%S"


class TargetNode
	def initialize(nid, address, name, rsids, location, fault)
		@nid = nid
		@address = address
		@name = name
		@rsids = rsids
		@location = location
		@fault = fault
		@time = Time.at(0)
		@before_read  = 0
		@before_write = 0
		@futures = []
	end

	attr_reader :nid

	def update_info(address, name, rsids, location, fault)
		@address = address
		@name = name
		@rsids = rsids
		@location = location
		@fault = fault
	end

	def refresh_async
		s = $net.get_session(*@address)
		s.timeout = 3
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
		ar = Array.new(12)
		ar[0] = @nid
		ar[1] = @name
		ar[2] = @address.to_s
		ar[3] = @location
		ar[4] = @rsids.join(',')

		if @fault
			ar[5] = "FAULT node"
			return ar
		end

		begin
			nread    = @futures[0].get
			nwrite   = @futures[1].get
			time     = @futures[2].get
			db_items = @futures[3].get
			psread   = (nread  - @before_read ) / @elapse
			pswrite  = (nwrite - @before_write) / @elapse

			@before_read  = nread
			@before_write = nwrite

			ar[5] = nread
			ar[6] = nwrite
			ar[7] = psread.to_i
			ar[8] = pswrite.to_i
			ar[9] = (psread + pswrite).to_i
			ar[10] = db_items
			ar[11] = time_format(time)

		rescue
			@before_read  = 0
			@before_write = 0
			ar[5] = "error: #{$!.to_s}"
		end

		ar
	end

	def time_format(t)
		if t
			Time.at(t).strftime(TIME_FORMAT)
		else
			""
		end
	end
end


class Top
	def initialize(cs_addr)
		@cs_addr = cs_addr
		@nodes = {}  # { nid => TargetNode }
		@nodes_sorted = []  # [TargetNode]
		update_nodes
		@simple = false
	end

	def toggle_simple
		if @simple
			@simple = false
		else
			@simple = true
		end
	end

	def update_nodes
		s = $net.get_session(*@cs_addr)
		s.timeout = 20

		fault_nids = s.call(:stat, 'fault')
		s.call(:stat, 'nodes').each {|nid,address,name,rsids,location|
			address = MessagePack::RPC::Address.load(address)
			fault = fault_nids.include?(nid)
			if node = @nodes[nid]
				node.update_info(address, name, rsids, location, fault)
			else
				@nodes[nid] = TargetNode.new(nid, address, name, rsids, location, fault)
			end
		}
		@nodes_sorted = @nodes.values.sort_by {|node| node.nid }
	end

	def refresh
		Curses.clear
		if @simple
			if Curses.stdscr.maxx >= 82
				format = FORMAT_LARGE_SIMPLE
			else
				format = FORMAT_SMALL_SIMPLE
			end
		else
			if Curses.stdscr.maxx >= 147
				format = FORMAT_LARGE
			else
				format = FORMAT_SMALL
			end
		end

		Curses.setpos(0, 0)
		title_line = format % TITLES
		nlines = title_line.count("\n")+1
		Curses.addstr(title_line)

		@nodes_sorted.each {|node|
			node.refresh_async
		}
		@nodes_sorted.each_with_index {|node, i|
			Curses.setpos((1+i)*nlines, 0)
			params = node.refresh_async_get
			line = format % params
			Curses.addstr(line)
		}

		Curses.refresh
	end

	def run
		i = 0
		while true
			before = Time.now

			refresh

			i += 1
			if i > 5
				i = 0
				update_nodes
			end

			elapse = Time.now - before
			if elapse < 0.5
				sleep 0.5 - elapse
			end
		end
	rescue
		$stderr.puts $!.inspect
	end
end

top = Top.new(cs_addr)

Curses.init_screen

begin
	th = Thread.start(&top.method(:run))

	while true
		ch = Curses.getch
		case ch
		when ?s
			top.toggle_simple
		when ?q
			break
		end
		#top.refresh
	end

ensure
	Curses.close_screen
end

