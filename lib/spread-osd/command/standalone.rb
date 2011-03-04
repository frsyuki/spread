require 'msgpack/rpc'
require 'digest/md5'
require 'digest/sha1'
require 'csv'
require 'cgi'
require 'spread-osd/lib/cclog'
require 'spread-osd/lib/ebus'
require 'spread-osd/lib/vbcode'
require 'spread-osd/logic/tsv_data'
require 'spread-osd/logic/weight'
require 'spread-osd/logic/fault_detector'
require 'spread-osd/logic/membership'
require 'spread-osd/logic/node'
require 'spread-osd/logic/okey'
require 'spread-osd/service/base'
require 'spread-osd/service/bus'
require 'spread-osd/service/process'
require 'spread-osd/service/rpc'
require 'spread-osd/service/rpc_gw'
require 'spread-osd/service/rpc_ds'
require 'spread-osd/service/rpc_cs'
require 'spread-osd/service/stat'
require 'spread-osd/service/stat_gw'
require 'spread-osd/service/stat_ds'
require 'spread-osd/service/config'
require 'spread-osd/service/config_gw'
require 'spread-osd/service/config_ds'
require 'spread-osd/service/config_cs'
require 'spread-osd/service/data_server'
require 'spread-osd/service/data_server_url'
require 'spread-osd/service/data_client'
require 'spread-osd/service/mds'
require 'spread-osd/service/mds_ha'
require 'spread-osd/service/mds_tt'
require 'spread-osd/service/mds_tc'
require 'spread-osd/service/mds_memcache'
require 'spread-osd/service/mds_cache'
require 'spread-osd/service/mds_cache_mem'
require 'spread-osd/service/mds_cache_memcached'
require 'spread-osd/service/gateway'
require 'spread-osd/service/gateway_ro'
require 'spread-osd/service/gw_http'
require 'spread-osd/service/sync'
require 'spread-osd/service/heartbeat'
require 'spread-osd/service/weight'
require 'spread-osd/service/balance'
require 'spread-osd/service/master_select'
require 'spread-osd/service/membership'
require 'spread-osd/service/rts'
require 'spread-osd/service/rts_file'
require 'spread-osd/service/rts_memory'
require 'spread-osd/service/slave'
require 'spread-osd/service/storage'
require 'spread-osd/service/storage_dir'
require 'spread-osd/service/ulog'
require 'spread-osd/service/ulog_file'
require 'spread-osd/service/ulog_memory'
require 'spread-osd/service/time_check'
require 'spread-osd/service/log'
require 'spread-osd/default'
require 'spread-osd/version'
require 'optparse'

include SpreadOSD

conf = DSConfigService.init
mds_uri = nil
mds_cache_uri = ""

op = OptionParser.new

(class<<self;self;end).module_eval do
	define_method(:usage) do |msg|
		puts op.to_s
		puts "error: #{msg}" if msg
		exit 1
	end
end

listen_host = '0.0.0.0'
listen_port = DS_DEFAULT_PORT

read_only_gw = false

op.on('-p', '--port PORT', "listen port") do |addr|
	if addr.include?(':')
		listen_host, listen_port = addr.split(':',2)
		listen_port = listen_port.to_i
		listen_port = DS_DEFAULT_PORT if listen_port == 0
	else
		listen_port = addr.to_i
	end
end

op.on('-l', '--listen HOST', "listen address") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
		port = DS_DEFAULT_PORT if port == 0
		listen_host = host
		listen_port = port
	else
		listen_host = addr
	end
end

op.on('-m', '--mds EXPR', "address of metadata server") do |s|
	mds_uri = s
end

op.on('-M', '--mds-cache EXPR', "mds cache") do |s|
	mds_cache_uri = s
end

op.on('-s', '--store PATH', "path to storage directory") do |path|
	conf.storage_path = path
end

op.on('-u', '--ulog PATH', "path to update log directory") do |path|
	conf.ulog_path = path
end

op.on('-r', '--rts PATH', "path to relay timestamp directory") do |path|
	conf.rts_path = path
end

op.on('-t', '--http PORT', "http listen port") do |addr|
	if addr.include?(':')
		host, port = addr.split(':',2)
		port = port.to_i
	else
		host = '0.0.0.0'
		port = addr.to_i
	end
	conf.http_gateway_address = Address.new(host, port)
end

op.on('--http-error-page PATH', 'path to eRuby template file') do |path|
	conf.http_gateway_error_template_file = path
end

op.on('--http-redirect-port PORT', Integer) do |port|
	conf.http_redirect_port = port
end

op.on('--http-redirect-path FORMAT') do |format|
	conf.http_redirect_path_format = format
end

op.on('-R', '--read-only', "read-only mode", TrueClass) do |b|
	read_only_gw = b
end

op.on('-N', '--read-only-name NAME', "read-only mode using the version name") do |name|
	read_only_gw = true
	conf.read_only_version = name
end

op.on('-T', '--read-only-time TIME', "read-only mode using the time", Integer) do |time|
	read_only_gw = true
	conf.read_only_version = time
end

op.on('--fault_store PATH', "path to fault status file") do |path|
	conf.fault_path = path
end

op.on('--membership_store PATH', "path to membership status file") do |path|
	conf.membership_path = path
end

op.on('-o', '--log PATH') do |path|
	conf.log_path = path
end

op.on('-v', '--verbose', "show debug messages", TrueClass) do |b|
	$log.level = 1 if b
end

op.on('--trace', "show debug and trace messages", TrueClass) do |b|
	$log.level = 0 if b
end

op.on('--color-log', "force to enable color log", TrueClass) do |b|
	$log.enable_color
end


begin
	op.parse!(ARGV)

	if ARGV.length != 0
		raise "unknown option: #{ARGV[0].dump}"
	end

	conf.self_address = Address.new('127.0.0.1', listen_port)
	conf.cs_address = conf.self_address

	conf.self_nid = 1
	conf.self_name = "standalone"
	conf.self_rsids = [1]

	a = conf.self_address.host
	if a.include?('.')
		s = a.split('.')[0,3].map{|v4| "%03d" % v4.to_i }.join('.')
	else
		s = a.split(':')[0,4].map{|v6| "%04x" % v6.to_i(16) }.join(':')
	end
	conf.self_location = "subnet-#{s}"

	unless conf.storage_path
		raise "--store option is required"
	end

	unless mds_uri
		mds_uri = "local:#{conf.storage_path}/mds.tct"
	end

	unless conf.ulog_path
		conf.ulog_path = conf.storage_path
		#raise "--ulog option is required"
	end

	unless conf.rts_path
		conf.rts_path = conf.storage_path
		#raise "--rts option is required"
	end

	unless conf.fault_path
		conf.fault_path = File.join(conf.storage_path, "fault")
	end

	unless conf.membership_path
		conf.membership_path = File.join(conf.storage_path, "membership")
	end

	unless conf.weight_path
		conf.weight_path = File.join(conf.storage_path, "weight")
	end

	if conf.http_redirect_path_format && !conf.http_redirect_port
		$log.warn "--http-redirect-port option is ignored"
	end

rescue
	usage $!.to_s
end


ProcessService.init
LogService.open!
StandaloneSyncService.init
RoutRobinWeightBalanceService.init
WeightMemberService.init
if conf.self_location.empty?
	FlatMasterSelectService.init
else
	LocationAwareMasterSelectService.init
end
StandaloneMembershipService.init
DataClientService.init
if read_only_gw
	ReadOnlyGatewayService.init
else
	GatewayService.init
end
if conf.http_gateway_address
	HTTPGatewayService.open!
end
StorageSelector.open!
UpdateLogSelector.open!
RelayTimeStampSelector.open!
SlaveService.init
DataServerService.init
DataServerURLService.init
DSStatService.init
MDSService.init
MDSCacheService.init
CachedMDSService.init
TimeCheckService.init

LogService.instance.log_event_bus

ProcessBus.run

StandaloneMembershipService.instance.rpc_add_node(conf.self_nid, conf.self_address, conf.self_name, conf.self_rsids, conf.self_location)
MDSService.instance.reopen(mds_uri)
MDSCacheService.instance.reopen(mds_cache_uri) if mds_cache_uri

net = ProcessBus.serve_rpc(DSRPCService.instance)
net.listen(listen_host, listen_port)

$log.info "start on #{listen_host}:#{listen_port}"

net.run

ProcessBus.shutdown

