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
require 'common'
require 'optparse'

include SpreadOSD

conf = GWConfigService.init

op = OptionParser.new
#op.banner += " <boot.yaml>"

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

listen_host = '0.0.0.0'
listen_port = GW_DEFAULT_PORT

op.on('-p', '--port PORT', "listen port") do |addr|
	if addr.include?(':')
		listen_host, listen_port = addr.split(':',2)
		listen_port = listen_port.to_i
		listen_port = GW_DEFAULT_PORT if listen_port == 0
	else
		listen_port = addr.to_i
	end
end

op.on('-m', '--cs ADDRESS', "address of config server") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	port = CS_DEFAULT_PORT if port == 0
	conf.cs_address = Address.new(host, port)
end

op.on('-f', '--fault_path PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('-b', '--membership PATH', "path to membership status file") do |path|
	conf.membership_path = path
end


begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

	unless conf.cs_address
		raise "--cs option is required"
	end

rescue
	usage $!.to_s
end


NetService.init
TimerService.init
HeartbeatClientService.init
MembershipClientService.init
MDSService.init
GatewayService.init
GWStatusService.init


MDSService.instance.open_blocking(conf.cs_address)


net = GWRPCService.serve

$ebus.call(:run)

$ebus.connect(:on_timer) do
	GC.start # FIXME
end

net.listen(listen_host, listen_port)

puts "start on #{listen_host}:#{listen_port}"

net.run

$ebus.call(:shutdown)

