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
require 'msgpack/rpc'
require 'json'
require 'pp'

def usage
	puts "Usage: #{File.basename($0)} <cs address[:port]> <command> [options]"
	puts "command:"
	puts "   get_data <key>                     get data"
	puts "   get_attrs <key>                    get attributes"
	puts "   gets_data <sid> <key>              get data using the snapshot"
	puts "   gets_attrs <sid> <key>             get attributes using the snapshot"
	puts "   read <key> <offset> <size>         get data with the offset and the size"
	puts "   reads <sid> <key> <offset> <size>  get data with the offset and the size"
	puts "   set_data <key> <data>              set data"
	puts "   set_attrs <key> <json>             set attributes"
	puts "   write <key> <offset> <data>        set data with the offset and the size"
	puts "   get <key>                          get data and attributes"
	puts "   gets <sid> <key>                   get data and attributes using the snapshot"
	puts "   set <key> <data> <json>            set data and attributes"
	puts "   remove <key>                       remove the data"
	puts "   select <expr> [cols...]            select attributes"
	puts "   selects <sid> <expr> [cols...]     select attributes using the snapshot"
	exit 1
end

if ARGV.length < 2
	usage
end

$net = MessagePack::RPC::SessionPool.new
addr = ARGV.shift
host, port = addr.split(':', 2)
port = port.to_i
port = 18800 if port == 0
$addr = [host,port]#Address.new(host, port)

cmd = ARGV.shift

def cmd_args(n)
	if n < 0
		return ARGV
	end
	usage if ARGV.length != n
	ARGV.map! {|ar| ar == '-' ? $stdin.read : ar }
	if n == 1
		ARGV[0]
	else
		ARGV
	end
end

def call(klass, *args)
	start = Time.now

	s = $net.get_session(*$addr)
	s.timeout = 20
	result = s.call(*args)
	if klass && result
		result = klass.new.from_msgpack(result)
	end

	finish = Time.now
	$stderr.puts "#{finish - start} sec."

	result
end

def select_argv
	if ARGV.length < 1
		usage
	end

	expr = ARGV.shift
	cols = ARGV
	cols = nil if cols.empty?

	conds = []
	order = nil
	order_col = nil
	limit = nil
	skip = nil

	expr.strip.split(/\s+/).each {|e|
		if e =~ /order=(\w+)(,str-asc|,str-desc|,num-asc|,num-desc)?/
			order = 1
			order_col = $~[1]
			case $~[2]
			when nil, ',str-asc'
				order = 1
			when ',str-desc'
				order = 2
			when ',num-asc'
				order = 3
			when ',num-desc'
				order = 4
			end
		elsif e =~ /limit=(\d+)/
			limit = $~[1].to_i
		elsif e =~ /skip=(\d+)/
			skip = $~[1].to_i
		elsif e =~ /(\w+)\=\=(\w+)/
			rval = $~[2]
			rval = rval.to_i if rval.to_i.to_s == rval
			conds << [$~[1], 0, rval]
		elsif e =~ /(\w+)\!\=(\w+)/
			rval = $~[2]
			rval = rval.to_i if rval.to_i.to_s == rval
			conds << [$~[1], 1, rval]
		elsif e =~ /(\w+)\<(\w+)/
			rval = $~[2]
			rval = rval.to_i if rval.to_i.to_s == rval
			conds << [$~[1], 2, rval]
		elsif e =~ /(\w+)\<\=(\w+)/
			rval = $~[2]
			rval = rval.to_i if rval.to_i.to_s == rval
			conds << [$~[1], 3, rval]
		elsif e =~ /(\w+)\>(\w+)/
			rval = $~[2]
			rval = rval.to_i if rval.to_i.to_s == rval
			conds << [$~[1], 4, rval]
		elsif e =~ /(\w+)\>\=(\w+)/
			rval = $~[2]
			rval = rval.to_i if rval.to_i.to_s == rval
			conds << [$~[1], 5, rval]
		else
			raise "invalid expression: #{e.dump}"
		end
	}

	$stderr.puts "select: cols=#{cols ? cols.join(',') : '*'}"
	$stderr.puts "  conds: #{conds.inspect}"
	$stderr.puts "  skip: #{skip}"
	$stderr.puts "  limit: #{limit}"
	$stderr.puts "  order: #{order_col} #{order}"

	return cols, conds, order, order_col, limit, skip
end

case cmd
when 'get'
	key = cmd_args(1)
	data, attrs = call(nil, :get, key)
	if data
		puts attrs.to_json
		$stdout.write data
	else
		$stderr.puts "nil"
	end

when 'gets'
	sid, key = cmd_args(2)
	data, attrs = call(nil, :gets, sid.to_i, key)
	if data
		puts attrs.to_json
		$stdout.write data
	else
		$stderr.puts "nil"
	end

when 'get_data'
	key = cmd_args(1)
	data = call(nil, :get_data, key)
	if data
		$stderr.puts "#{data.size} bytes"
		$stdout.write data
	else
		$stderr.puts "nil"
	end

when 'gets_data'
	sid, key = cmd_args(2)
	data = call(nil, :gets_data, sid.to_i, key)
	if data
		$stderr.puts "#{data.size} bytes"
		$stdout.write data
	else
		$stderr.puts "nil"
	end

when 'get_attrs'
	key = cmd_args(1)
	attrs = call(nil, :get_attrs, key)
	if attrs
		puts attrs.to_json
	else
		puts "nil"
	end

when 'gets_attrs'
	sid, key = cmd_args(2)
	attrs = call(nil, :gets_attrs, sid.to_i, key)
	if attrs
		puts attrs.to_json
	else
		puts "nil"
	end

when 'read'
	key, offset, size = cmd_args(3)
	data = call(nil, :read, key, offset.to_i, size.to_i)
	$stderr.puts "#{data.size} bytes"
	$stdout.write data

when 'reads'
	sid, key, offset, size = cmd_args(4)
	data = call(nil, :reads, sid.to_i, key, offset.to_i, size.to_i)
	$stderr.puts "#{data.size} bytes"
	$stdout.write data

when 'set'
	key, data, json = cmd_args(3)
	attrs = JSON.parse(json)
	pp call(nil, :set, key, data, attrs)

when 'set_data'
	key, data = cmd_args(2)
	pp call(nil, :set_data, key, data)

when 'set_attrs'
	key, json = cmd_args(2)
	attrs = JSON.parse(json)
	pp call(nil, :set_attrs, key, attrs)

when 'write'
	key, offset, data = cmd_args(3)
	pp call(nil, :write, key, offset, data)

when 'remove'
	key = cmd_args(1)
	pp call(nil, :remove, key)

when 'select'
	args = select_argv
	pp call(nil, :select, *args)

when 'selects'
	sid = ARGV.shift.to_i
	args = select_argv
	pp call(nil, :selects, sid, *args)

else
	$stderr.puts "unknown command #{cmd}"
	$stderr.puts ""
	usage
end

