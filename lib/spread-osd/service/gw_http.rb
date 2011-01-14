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
module SpreadOSD


class HTTPGatewayService < Service
	def self.open!
		require 'rack'
		require 'webrick'
		require 'thread'
		instance.init(ConfigBus.http_gateway_address)
	end

	def initialize
		@thread = nil
		@server = nil
	end

	def init(addr)
		opt = {
			:BindAddress => addr.host,
			:Port => addr.port,
		}
		@server = ::WEBrick::HTTPServer.new(opt)
		ins = self

		app = ::Rack::URLMap.new({
			'/data'  => Proc.new {|env| ins.call_data(env) },
			'/attrs' => Proc.new {|env| ins.call_attrs(env) },
			'/rpc'   => Proc.new {|env| ins.call_rpc(env) },
		})

		@server.mount("/", ::Rack::Handler::WEBrick, app)
		@thread = Thread.new do
			@server.start
		end
	end

	# data/
	#    sid=i              get=>gets, read=>reads
	#    offset=i           get=>read, set=write
	#    offset=i&size=i    get=>read
	#  get(data/key)                          => get/gets/read/reads_data
	#  put(data/key, data)                    => set/write_data
	# post(data/key, data)                    => set/write_data
	# delete(data/key)                        => remove_data
	def call_data(env)
		case env['REQUEST_METHOD']
		when 'GET'
			http_data_get(env)
		when 'POST'
			http_data_get(env)
		when 'PUT'
			http_data_put(env)
		when 'DELETE'
			http_data_delete(env)
		else
			body = ["<html><head></head><body><h1>405 Method Not Allowed</h1></body></html>"]
			[405, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_data_get(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		sid    = optional_int(request, 'sid')
		offset = optional_int(request, 'offset')
		if offset
			size = require_int(request, 'size')
		else
			size = optional_int(request, 'size')
			if size
				offset = 0
			end
		end

		if offset
			if sid
				data = submit(:reads, sid, key, offset, size)
			else
				data = submit(:read, key, offset, size)
			end
		else
			if sid
				data = submit(:gets_data, sid, key)
			else
				data = submit(:get_data, key)
			end
		end

		if data
			[200, {'Content-Type'=>'application/octet-stream'}, data]
		else
			body = ["<html><head></head><body><h1>404 Not Found</h1></body></html>"]
			[404, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_data_put(env)
		key = get_key_path_info(env)

		# TODO

		if env['HTTP_EXPECT'] == '100-continue'
			body = ["<html><head></head><body><h1>417 Exception Failed</h1></body></html>"]
			return [417, {'Content-Type'=>'text/html'}, body]
		end

		data = env['rack.input'].read

		# TODO
		okey = submit(:set_data, key, data)

		# FIXME return okey?
		body = ["<html><head></head><body><h1>202 Accepted</h1></body></html>"]
		[202, {'Content-Type'=>'text/html'}, body]
	end

	def http_data_delete(env)
		key = get_key_path_info(env)

		removed = submit(:remove, key)
		# TODO

		if removed
			body = ["<html><head></head><body><h1>200 OK</h1></body></html>"]
			[200, {'Content-Type'=>'text/html'}, body]
		else
			body = ["<html><head></head><body><h1>204 No Content</h1></body></html>"]
			[204, {'Content-Type'=>'text/html'}, body]
		end
	end

	# attrs/
	#    sid=i
	#    attrs=
	#    format=json        json, tsv, msgpack
	#  get(attrs/key)                         => get/gets_attrs
	# post(attrs/key, json)                   => set_attrs
	def call_attrs(env)
		case env['REQUEST_METHOD']
		when 'GET'
			http_attrs_get(env)
		when 'POST'
			http_attrs_get(env)
		else
			body = ["<html><head></head><body><h1>405 Method Not Allowed</h1></body></html>"]
			[405, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_attrs_get(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		sid    = optional_int(request, 'sid')
		format = require_str(request, 'format')
		format ||= 'json'

		if sid
			attrs = submit(:gets_attrs, sid, key)
		else
			attrs = submit(:get_attrs, key)
		end

		# TODO

		if attrs
			attrs, ct = format_attrs(attrs, format)
			body = [attrs]
			[200, {'Content-Type'=>ct}, body]
		else
			body = ["<html><head></head><body><h1>404 Not Found</h1></body></html>"]
			[404, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_attrs_post(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		attrs  = require_str(request, 'attrs')
		format = require_str(request, 'format')
		format ||= 'json'

		attrs = parse_attrs(attrs, format)

		okey = submit(:set_attrs, key, attrs)

		# TODO

		if attrs
			attrs, ct = format_attrs(attrs, format)
			body = [attrs]
			[200, {'Content-Type'=>ct}, body]
		else
			body = ["<html><head></head><body><h1>404 Not Found</h1></body></html>"]
			[404, {'Content-Type'=>'text/html'}, body]
		end
	end

	# rpc/
	#  get(rpc/cmd?k=v)
	# post(rpc/cmd?k=v)
	#    cmd:
	#      get           [sid=] key= format=
	#      get_data      [sid=] key=
	#      get_attrs     [sid=] key= format=
	#      read          [sid=] key= offset= size=
	#      set           key= [data=] [attrs= [format=]]
	#      set_data      key= data=
	#      set_attrs     key= attrs= format=
	#      write         key= offset= data=
	#      remove        key=
	#      select        conds= [cols=] [order=] [order_col=] [limit=] [skip=] [sid=]
	#
	def call_rpc(env)
		m = env['REQUEST_METHOD']
		if m != 'GET' && m != 'POST'
			body = ["<html><head></head><body><h1>405 Method Not Allowed</h1></body></html>"]
			return [405, {'Content-Type'=>'text/html'}, body]
		end
		# TODO
		case get_cmd_path_info(env)
		when 'get'
			http_rpc_get(env)
		when 'get_data'
			http_rpc_get_data(env)
		when 'get_attrs'
			http_rpc_get_attrs(env)
		when 'read'
			http_rpc_get_data(env)
		when 'set'
			http_rpc_set(env)
		when 'set_data'
			http_rpc_set(env)
		when 'set_attrs'
			http_rpc_set(env)
		when 'write'
			http_rpc_set(env)
		when 'remove'
			http_rpc_remove(env)
		when 'select'
			http_rpc_select(env)
		else
			# FIXME
		end
	end

	def http_rpc_get(env)
		request = ::Rack::Request.new(env)
		key    = require_str(request, 'key')
		sid    = optional_int(request, 'sid')
		format = optional_str(request, 'format')
		format ||= 'json'

		if sid
			# FIXME
			data, attrs = submit(:gets, sid, key)
		else
			# FIXME
			data, attrs = submit(:get, key)
		end

		# TODO

		if data
			attrs, ct = format_attrs(attrs, format)
			# FIXME
		else
			body = ["<html><head></head><body><h1>404 Not Found</h1></body></html>"]
			[404, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_rpc_get_data(env)
		request = ::Rack::Request.new(env)
		key    = require_str(request, 'key')
		sid    = optional_int(request, 'sid')
		offset = optional_int(request, 'offset')
		if offset
			size = require_int(request, 'size')
		else
			size = optional_int(request, 'size')
			if size
				offset = 0
			end
		end

		if offset
			if sid
				# FIXME
				data = submit(:reads, sid, key, offset, size)
			else
				# FIXME
				data = submit(:read, key, offset, size)
			end
		else
			if sid
				# FIXME
				data = submit(:gets_data, sid, key)
			else
				# FIXME
				data = submit(:get_data, key)
			end
		end

		# TODO
		if data
			[200, {'Content-Type'=>'application/octet-stream'}, data]
		else
			body = ["<html><head></head><body><h1>404 Not Found</h1></body></html>"]
			[404, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_rpc_get_attrs(env)
		request = ::Rack::Request.new(env)
		key    = require_str(request, 'key')
		sid    = optional_int(request, 'sid')
		format = optional_str(request, 'format')
		format ||= 'json'

		attrs = parse_attrs(attrs, format)

		if sid
			attrs = submit(:gets_attrs, sid, key, attrs)
		else
			attrs = submit(:get_attrs, key, attrs)
		end

		# TODO

		if attrs
			attrs, ct = format_attrs(attrs, format)
			body = [attrs]
			[200, {'Content-Type'=>ct}, body]
		else
			body = ["<html><head></head><body><h1>404 Not Found</h1></body></html>"]
			[404, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_rpc_set(env)
		request = ::Rack::Request.new(env)
		key    = require_str(request, 'key')
		attrs  = require_str(request, 'attrs')
		if attrs
			format = optional_str(request, 'format')
			format ||= 'json'
		else
			data   = require_str(request, 'data')
		end

		if attrs
			attrs = parse_attrs(attrs, format)
			if data
				okey = submit(:set, key, data, attrs)
			else
				okey = submit(:set_attrs, key, attrs)
			end
		else
			okey = submit(:set_data, key, data)
		end

		# TODO okey
		body = ["<html><head></head><body><h1>200 OK</h1></body></html>"]
		[200, {'Content-Type'=>'text/html'}, body]
	end

	def http_rpc_remove(env)
		request = ::Rack::Request.new(env)
		key    = require_str(request, 'key')

		removed = submit(:remove, key)

		if removed
			body = ["<html><head></head><body><h1>200 OK</h1></body></html>"]
			[200, {'Content-Type'=>'text/html'}, body]
		else
			body = ["<html><head></head><body><h1>204 No Content</h1></body></html>"]
			[204, {'Content-Type'=>'text/html'}, body]
		end
	end

	def http_rpc_select(env)
		request = ::Rack::Request.new(env)
		sid    = optional_int(request, 'sid')
		conds  = require_str(request, 'conds')
		cols   = optional_str(request, 'cols')
		order  = optional_str(request, 'order')
		order_col  = optional_str(request, 'order_col')
		limit  = optional_int(request, 'limit')
		skip   = optional_int(request, 'skip')

		# FIXME order
		# FIXME conds

		# TODO
	end

	private
	def require_str(request, k)
		# FIXME check error
		request.POST[k] || request.POST[k]
	end

	def require_int(request, k)
		str = require_str(request, k)
		if str
			# FIXME check error
			str.to_i
		else
			nil
		end
	end

	def optional_str(request, k)
		request.POST[k] || request.POST[k]
	end

	def optional_int(request, k)
		str = optional_str(request, k)
		if str
			# FIXME check error
			str.to_i
		else
			nil
		end
	end

	def get_cmd_path_info(env)
		env['PATH_INFO'][1..-1]  # remove front '/' character
	end

	def get_key_path_info(env)
		env['PATH_INFO'][1..-1]  # remove front '/' character
	end

	def parse_attrs(attrs, format)
		case format
		when 'json'
			return JSON.load(attrs)
		when 'msgpack'
			return MessagePack.unpack(attrs)
		when 'tsv'
			r = {}
			attrs.split("\n").map {|line|
				k, v, _ = line.split("\t")
				r[k] = v || ""
			}
			return r
		else
			# FIXME
		end
	end

	def format_attrs(attrs, format)
		# FIXME
		# returns str, content_type
		case format
		when 'json'
			return JSON.dump(attrs), 'application/json'
		when 'msgpack'
			return MessagePack.pack(attrs), 'application/x-msgpack'
		when 'tsv'
			data = attrs.map {|k,v| "#{k}\t#{v}" }.join("\n")
			return data, 'text/tab-separated-values'
		else
			# FIXME
		end
	end

	protected
	class Responder
		def initialize
			@mutex = Mutex.new
			@cond = ConditionVariable.new
			@sent = false
			@retval = nil
			@err = nil
		end

		attr_reader :retval
		attr_reader :err

		def wait
			@mutex.synchronize do
				until @sent
					@cond.wait(@mutex)
				end
			end
		end

		def sent?
			@sent
		end

		def result(retval, err=nil)
			@mutex.synchronize do
				unless @sent
					@retval = retval
					@err = err
					@sent = true
					@cond.signal
				end
			end
			nil
		end

		def error(err, retval = nil)
			result(retval, err)
		end
	end

	def submit(name, *args)
		$log.warn { "http rpc: #{name} #{args}" }

		r = Responder.new

		ProcessBus.submit {
			dispatch(name, args, r)
		}

		r.wait

		if r.err
			# FIXME
			raise r.err
		else
			return r.retval
		end

		raise
	end

	def dispatch(name, args, r)
		result = GWRPCBus.__send__(name, *args)
		if result.is_a?(MessagePack::RPC::AsyncResult)
			result.set_responder(r)
		else
			r.result(result)
		end
	rescue => e
		msg = ["http rpc error on #{name}: #{e}"]
		e.backtrace.each {|bt| msg <<  "    #{bt}" }
		$log.error msg.join("\n")
		r.error(e)
	end
end


end
