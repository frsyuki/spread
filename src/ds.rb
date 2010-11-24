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

conf = DSConfigService.init

op = OptionParser.new
#op.banner += " <boot.yaml>"

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

listen_host = nil
listen_port = nil

op.on('-i', '--nid ID', Integer, "unieque node id") do |nid|
	conf.self_nid = nid
end

op.on('-n', '--name NAME', "node name") do |name|
	conf.self_name = name
end

op.on('-a', '--address ADDRESS', "listen address") do |addr|
	host, port = addr.split(':',2)
	port = port.to_i
	port = DS_DEFAULT_PORT if port == 0
	conf.self_address = Address.new(host, port)
	listen_host = host
	listen_port = port
end

op.on('-g', '--rsid IDs', "replication set IDs") do |ids|
	conf.self_rsids = ids.split(',').map {|id| id.to_i }
end

op.on('-s', '--storage PATH', "path to storage directory") do |path|
	conf.storage_path = path
end

op.on('-u', '--ulog PATH', "path to update log directory") do |path|
	conf.ulog_path = path
end

op.on('-r', '--rlog PATH', "path to relay log directory") do |path|
	conf.rlog_path = path
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

	unless conf.self_nid
		raise "--nid option is required"
	end

	unless conf.self_name
		raise "--name option is required"
	end

	unless conf.self_address
		raise "--address option is required"
	end

	unless conf.self_rsids
		raise "--rsid option is required"
	end

	unless conf.storage_path
		raise "--storage option is required"
	end

	unless conf.ulog_path
		raise "--ulog option is required"
	end

	unless conf.rlog_path
		raise "--rlog option is required"
	end

	unless conf.cs_address
		raise "--cs option is required"
	end

rescue
	usage $!.to_s
end


NetService.init
TimerService.init
HeartbeatMemberService.init
MembershipMemberService.init
StorageService.init
DSStatusService.init

net = DSRPCService.serve

$ebus.call(:run)

net.listen(listen_host, listen_port)

puts "start on #{listen_host}:#{listen_port}"

net.run

$ebus.call(:shutdown)

