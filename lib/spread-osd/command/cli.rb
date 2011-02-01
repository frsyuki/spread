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
	puts "   get <key>                           get data and attributes"
	puts "   gett <time> <key>                   get data and attributes using the time"
	puts "   getv <vname> <key>                  get data and attributes using the version name"
	puts "   get_data <key>                      get data"
	puts "   gett_data <time> <key>              get data using the time"
	puts "   getv_data <vname> <key>             get data using the version name"
	puts "   get_attrs <key>                     get attributes"
	puts "   gett_attrs <time> <key>             get attributes using the time"
	puts "   getv_attrs <vname> <key>            get attributes using the version name"
	puts "   read <key> <offset> <size>          get data with the offset and the size"
	puts "   readt <time> <key> <offset> <size>  get data with the offset and the size using version time"
	puts "   readv <vname> <key> <offset> <size> get data with the offset and the size using version name"
	puts "   add <key> <data> <json>             set data and attributes"
	puts "   addv <vname> <key> <data> <json>    set data and attributes with version name"
	puts "   add_data <key> <data>               set data"
	puts "   addv_data <vname> <key> <data>      set data with version name"
	puts "   update_attrs <key> <json>           update attributes"
	puts "   remove <key>                        remove the data and attributes"
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

when 'gett'
	vtime, key = cmd_args(2)
	data, attrs = call(nil, :gett, vtime.to_i, key)
	if data
		puts attrs.to_json
		$stdout.write data
	else
		$stderr.puts "nil"
	end

when 'getv'
	vname, key = cmd_args(2)
	data, attrs = call(nil, :getv, vname, key)
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

when 'gett_data'
	vtime, key = cmd_args(2)
	data = call(nil, :gett_data, vtime.to_i, key)
	if data
		$stderr.puts "#{data.size} bytes"
		$stdout.write data
	else
		$stderr.puts "nil"
	end

when 'getv_data'
	vname, key = cmd_args(2)
	data = call(nil, :getv_data, vname, key)
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

when 'gett_attrs'
	vtime, key = cmd_args(2)
	attrs = call(nil, :gett_attrs, vtime.to_i, key)
	if attrs
		puts attrs.to_json
	else
		puts "nil"
	end

when 'getv_attrs'
	vname, key = cmd_args(2)
	attrs = call(nil, :getv_attrs, vname, key)
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

when 'readt'
	vtime, key, offset, size = cmd_args(4)
	data = call(nil, :readt, vtime.to_i, key, offset.to_i, size.to_i)
	$stderr.puts "#{data.size} bytes"
	$stdout.write data

when 'readt'
	vname, key, offset, size = cmd_args(4)
	data = call(nil, :readv, vname.to_i, key, offset.to_i, size.to_i)
	$stderr.puts "#{data.size} bytes"
	$stdout.write data

when 'add'
	key, data, json = cmd_args(3)
	attrs = JSON.parse(json)
	pp call(nil, :add, key, data, attrs)

when 'addv'
	vname, key, data, json = cmd_args(4)
	attrs = JSON.parse(json)
	pp call(nil, :addv, vname, key, data, attrs)

when 'add_data'
	key, data = cmd_args(2)
	pp call(nil, :add_data, key, data)

when 'addv_data'
	vname, key, data = cmd_args(3)
	pp call(nil, :addv_data, vname, key, data)

when 'update_attrs'
	key, json = cmd_args(2)
	attrs = JSON.parse(json)
	pp call(nil, :update_attrs, key, attrs)

when 'remove'
	key = cmd_args(1)
	pp call(nil, :remove, key)

else
	$stderr.puts "unknown command #{cmd}"
	$stderr.puts ""
	usage
end

