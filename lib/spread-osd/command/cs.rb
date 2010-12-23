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
require 'spread-osd/common'
require 'optparse'

include SpreadOSD

conf = CSConfigService.init

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

storage_path = nil

listen_host = '0.0.0.0'
listen_port = CS_DEFAULT_PORT

op.on('-p', '--port PORT', "listen port") do |addr|
	if port.include?(':')
		listen_host, listen_port = addr.split(':',2)
		listen_port = listen_port.to_i
		listen_port = CS_DEFAULT_PORT if listen_port == 0
	else
		listen_port = addr.to_i
	end
end

op.on('-s', '--storage PATH', "path to base directory") do |path|
	storage_path = path
end

op.on('-f', '--fault_path PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('-b', '--membership PATH', "path to membership status file") do |path|
	conf.membership_path = path
end

op.on('-t', '--mds ADDRESSes', "addresses of metadata server") do |addrs|
	conf.mds_addrs = addrs
end


begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

	unless conf.mds_addrs
		raise "--mds option is required"
	end

	if !conf.fault_path && storage_path
		conf.fault_path = File.join(storage_path, "fault")
	end

	if !conf.membership_path && storage_path
		conf.membership_path = File.join(storage_path, "membership")
	end

rescue
	usage $!.to_s
end

NetService.init
TimerService.init
HeartbeatServerService.init
MembershipManagerService.init
CSStatusService.init

net = CSRPCService.serve

$ebus.call(:run)

net.listen(listen_host, listen_port)

puts "start on #{listen_host}:#{listen_port}"

net.run

$ebus.call(:shutdown)

