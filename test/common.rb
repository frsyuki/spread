here = File.expand_path(File.dirname(__FILE__))

RUBY = ENV["RUBY"] || "ruby"
TTSERVER = ENV["TTSERVER"] || "ttserver"

DATA_DIR = ENV["DATA_DIR"] || "#{here}/tmp-#{Time.now.strftime("%Y-%m-%d.%H-%M-%S")}.#{Process.pid}"

CMD_BASE = "#{RUBY} -I#{here}/../lib #{here}/../lib/spread-osd/command"
CMD_CS  = "#{CMD_BASE}/cs.rb"
CMD_DS  = "#{CMD_BASE}/ds.rb"
CMD_GW  = "#{CMD_BASE}/gw.rb"
CMD_CTL = "#{CMD_BASE}/ctl.rb"

CS_PORT = (ENV["CS_PORT"] || 49700).to_i
DS_PORT = (ENV["DS_PORT"] || 49900).to_i
GW_PORT = (ENV["GW_PORT"] || 49800).to_i
MDS_PORT = (ENV["MDS_PORT"] || 49600).to_i
DS_HTTP_PORT = (ENV["GW_HTTP_PORT"] || 49400).to_i
GW_HTTP_PORT = (ENV["GW_HTTP_PORT"] || 49500).to_i

if ENV["NO_TRACE"]
	OPT = ENV["OPT"] || "--color-log"
	TTOPT = ENV["TTOPT"] || ""
else
	OPT = ENV["OPT"] || "--trace --color-log"
	TTOPT = ENV["TTOPT"] || "-ld"
end

begin
require 'rubygems'
rescue LoadError
end
require 'chukan'
require 'msgpack/rpc'
require 'fileutils'
require 'json'

require 'net/http'
Net::HTTP.version_1_2

include Chukan
include Chukan::Test

class ServerProcess < Chukan::LocalProcess
	def host
		"127.0.0.1"
	end

	protected
	def init_data_dir(subdir)
		ddir = "#{DATA_DIR}/#{subdir}"
		FileUtils.rm_rf(ddir)
		FileUtils.mkdir_p(ddir)
		ddir
	end
end

class MDSProcess < ServerProcess
	def initialize(*args)
		@port = MDS_PORT

		ddir = init_data_dir("mds")
		super("#{TTSERVER} -port #{@port} #{TTOPT} #{args.join(' ')} #{ddir}/mds.tct")
	end

	attr_reader :port

	def join_started
		stdout_join('started')
	end
end

class CtlProcess < Chukan::LocalProcess
	def initialize(host, port, *args)
		super("#{CMD_CTL} #{host}:#{port} #{args.join(' ')}")
		set_display("ctl #{args[0]}")
	end
end

class CSProcess < ServerProcess
	def initialize(*args)
		@port = CS_PORT

		ddir = init_data_dir("cs")
		super("#{CMD_CS} --mds tt:127.0.0.1:#{MDS_PORT} -p #{@port} -s #{ddir} #{args.join(' ')} #{OPT}")

		set_display("cs")
	end

	attr_reader :port

	def join_started
		stdout_join('start on')
	end

	def show_stat
		CtlProcess.new(host, port, "stat").join
	end

	def show_nodes
		CtlProcess.new(host, port, "nodes").join
	end

	def show_weight
		CtlProcess.new(host, port, "weight").join
	end

	def show_version
		CtlProcess.new(host, port, "version").join
	end

	def show_items
		CtlProcess.new(host, port, "items").join
	end

	def show_snapshot
		CtlProcess.new(host, port, "snapshot").join
	end

	def add_snapshot(name)
		CtlProcess.new(host, port, "add_snapshot", name).join
	end
end

class DSProcess < ServerProcess
	def initialize(nid, rsid, *args)
		@nid = nid
		@rsid = rsid
		@port = DS_PORT+nid
		@http_port = DS_HTTP_PORT+nid

		ddir = init_data_dir("ds#{nid}")
		super("#{CMD_DS} -c 127.0.0.1:#{CS_PORT} -s #{ddir} -i #{nid} -n node#{nid} -g #{rsid} -a 127.0.0.1:#{@port} -t #{@http_port} #{args.join(' ')} #{OPT}")

		set_display("ds#{nid} rsid=#{rsid}")
	end

	attr_reader :port
	attr_reader :http_port
	attr_reader :nid
	attr_reader :rsid

	def join_started
		stdout_join('start on')
	end

	def client
		MessagePack::RPC::Client.new(host, @port)
	end

	def http_client(path, &block)
		Net::HTTP.start("127.0.0.1", @http_port, &block)
	end
end

class GWProcess < ServerProcess
	def initialize(n, *args)
		@port = GW_PORT+n
		@http_port = GW_HTTP_PORT+n

		super("#{CMD_GW} -c 127.0.0.1:#{CS_PORT} -p #{port} -t #{@http_port} #{args.join(' ')} #{OPT}")

		set_display("gw#{n}")
	end

	attr_reader :port
	attr_reader :http_port

	def join_started
		stdout_join('start on')
	end

	def client
		MessagePack::RPC::Client.new(host, @port)
	end

	def http_client(&block)
		Net::HTTP.start("127.0.0.1", @http_port, &block)
	end
end


def start_mds(*args)
	mds = MDSProcess.new(*args)
	mds.join_started
	mds
end

def start_cs(*args)
	cs = CSProcess.new(*args)
	cs.join_started
	cs
end

def start_ds(nid, rsid, *args)
	ds = DSProcess.new(nid, rsid, *args)
	ds.join_started
	ds
end

def start_gw(n=0, *args)
	gw = GWProcess.new(n, *args)
	gw.join_started
	gw
end

def start_memcached(port, *args)
	m = spawn("memcached -U 0 -p #{port} #{args.join(' ')}")
	m
end

def term_all(*procs)
	procs.each {|pr| pr.term rescue p($!) }
	procs.each {|pr| pr.join rescue p($!) }
end

