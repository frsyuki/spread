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
		require 'json'
		require 'thread'
		instance.init(ConfigBus.http_gateway_address)
	end

	DEFAULT_FORMAT = 'json'

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
		me = self

		app = ::Rack::URLMap.new({
			'/data'     => Proc.new {|env| me.call_data(env)     },
			'/attrs'    => Proc.new {|env| me.call_attrs(env)    },
			'/rpc'      => Proc.new {|env| me.call_rpc(env)      },
			'/direct'   => Proc.new {|env| me.call_direct(env)   },
			'/redirect' => Proc.new {|env| me.call_redirect(env) },
		})

		@server.mount("/", ::Rack::Handler::WEBrick, app)
		@thread = Thread.new do
			@server.start
		end
	end

	# data/<key>
	#    sid=i              get=>gets
	#  get(data/key)                          => get/gets
	# post(data/key, data)                    => set
	#  put(data/key, data)                    => set
	def call_data(env)
		case env['REQUEST_METHOD']
		when 'GET'
			http_data_get(env)
		when 'POST'
			http_data_post(env)
		when 'PUT'
			http_data_put(env)
		else
			return html_response(405, 'Method Not Allowed')
		end
	end

	def http_data_get(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		sid = optional_int(request, 'sid')
		check_request(request, %w[sid])

		if sid
			data = submit(GWRPCBus, :gets_data, sid, key)
		else
			data = submit(GWRPCBus, :get_data, key)
		end

		if data
			[200, {'Content-Type'=>'application/octet-stream'}, data]
		else
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_data_put(env)
		key = get_key_path_info(env)

		if env['HTTP_EXPECT'] == '100-continue'
			return html_response(417, 'Exception Failed')
		end

		# FIXME check_request

		data = env['rack.input'].read

		okey = submit(GWRPCBus, :set_data, key, data)

		# FIXME return okey?
		return html_response(202, 'Accepted')
	end

	def http_data_post(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		data = require_str(request, 'data')
		check_request(request, %w[data])

		okey = submit(GWRPCBus, :set_data, key, data)

		# FIXME return okey?
		return html_response(200, 'OK')
	end

	#def http_data_delete(env)
	#	key = get_key_path_info(env)
	#
	#	# FIXME check_request
	#
	#	# TODO remove?
	#	removed = submit(GWRPCBus, :remove_data, key)
	#
	#	if removed
	#		return html_response(200, 'OK')
	#	else
	#		return html_response(204, 'No Content')
	#	end
	#end


	# redirect/<key>
	#    sid=i              get=>gets
	#  get(data/key)                          => redirect
	def call_redirect(env)
		case env['REQUEST_METHOD']
		when 'GET'
			http_redirect_get(env)
		else
			return html_response(405, 'Method Not Allowed')
		end
	end

	def http_redirect_get(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		sid = optional_int(request, 'sid')
		check_request(request, %w[sid])

		if sid
			url = submit(GWRPCBus, :urls, sid, key)
		else
			url = submit(GWRPCBus, :url, key)
		end

		unless url
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end

		if url
			body = ["302 Found"]
			return [302, {'Content-Type'=>'text/plain', 'Location'=>url}, body]
		else
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end


	# attrs/<key>
	#    sid=i
	#    attrs=
	#    format=json        json, tsv, msgpack
	#  get(attrs/key)                         => get/gets_attrs
	# post(attrs/key, json)                   => set_attrs
	#  put(attrs/key)                         => set_attrs
	# TODO delete
	def call_attrs(env)
		case env['REQUEST_METHOD']
		when 'GET'
			http_attrs_get(env)
		when 'POST'
			http_attrs_post(env)
		when 'PUT'
			http_attrs_put(env)
		else
			return html_response(405, 'Method Not Allowed')
		end
	end

	def http_attrs_get(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		sid    = optional_int(request, 'sid')
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[sid format])

		if sid
			attrs = submit(GWRPCBus, :gets_attrs, sid, key)
		else
			attrs = submit(GWRPCBus, :get_attrs, key)
		end

		if attrs
			attrs, ct = format_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			body = [attrs]
			[200, {'Content-Type'=>ct}, body]
		else
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_attrs_post(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		attrs  = require_str(request, 'attrs')
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[attrs format])

		attrs = parse_attrs(attrs, format)
		unless attrs
			return html_response(400, 'Bad Request', "unknown format `#{format}'")
		end

		okey = submit(GWRPCBus, :set_attrs, key, attrs)

		# TODO okey
		return html_response(200, 'OK')
	end

	def http_attrs_put(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[format])

		if env['HTTP_EXPECT'] == '100-continue'
			return html_response(417, 'Exception Failed')
		end

		attrs = env['rack.input'].read
		attrs = parse_attrs(attrs, format)
		unless attrs
			return html_response(400, 'Bad Request', "unknown format `#{format}'")
		end

		okey = submit(GWRPCBus, :set_attrs, key, attrs)

		# TODO okey
		return html_response(202, 'Accepted')
	end


	# rpc/<cmd>
	#  get(rpc/cmd?k=v)
	# post(rpc/cmd?k=v)
	#    cmd:
	#      get_data      [sid=] key=
	#      get_attrs     [sid=] key= format=
	#      set           key= [data=] [attrs= [format=]]
	#      set_data      key= data=
	#      set_attrs     key= attrs= format=
	#      remove        key=
	#      url           [sid=] key=
	#      select        conds= [cols=] [order=] [order_col=] [limit=] [skip=] [sid=]
	#
	def call_rpc(env)
		m = env['REQUEST_METHOD']
		if m != 'GET' && m != 'POST'
			return html_response(405, 'Method Not Allowed')
		end
		case get_cmd_path_info(env)
		when 'get_data'
			http_rpc_get_data(env)
		when 'get_attrs'
			http_rpc_get_attrs(env)
		when 'set'
			http_rpc_set(env)
		when 'set_data'
			http_rpc_set(env)
		when 'set_attrs'
			http_rpc_set(env)
		when 'remove'
			http_rpc_remove(env)
		when 'url'
			http_rpc_url(env)
		when 'select'
			http_rpc_select(env)
		else
			return html_response(406, 'Not Acceptable Method')
		end
	end

	def http_rpc_get_data(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		sid = optional_int(request, 'sid')
		check_request(request, %w[key sid])

		if sid
			data = submit(GWRPCBus, :gets_data, sid, key)
		else
			data = submit(GWRPCBus, :get_data, key)
		end

		if data
			body = [data]
			[200, {'Content-Type'=>'application/octet-stream'}, body]
		else
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_rpc_get_attrs(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		sid = optional_int(request, 'sid')
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[key sid format])

		if sid
			attrs = submit(GWRPCBus, :gets_attrs, sid, key)
		else
			attrs = submit(GWRPCBus, :get_attrs, key)
		end

		if attrs
			attrs, ct = format_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			body = [attrs]
			[200, {'Content-Type'=>ct}, body]
		else
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_rpc_set(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		attrs = optional_str(request, 'attrs')
		if attrs
			format = optional_str(request, 'format')
			format ||= DEFAULT_FORMAT
			check_request(request, %w[key attrs format])
		else
			data   = require_str(request, 'data')
			check_request(request, %w[key data])
		end

		if attrs
			attrs = parse_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			if data
				okey = submit(GWRPCBus, :set, key, data, attrs)
			else
				okey = submit(GWRPCBus, :set_attrs, key, attrs)
			end
		else
			okey = submit(GWRPCBus, :set_data, key, data)
		end

		# TODO okey
		return html_response(200, 'OK')
	end

	def http_rpc_remove(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		check_request(request, %w[key])

		removed = submit(GWRPCBus, :remove, key)

		if removed
			return html_response(200, 'OK')
		else
			return html_response(204, 'No Content')
		end
	end

	def http_rpc_url(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		sid = optional_int(request, 'sid')
		check_request(request, %w[key sid])

		if sid
			url = submit(GWRPCBus, :urls, sid, key)
		else
			url = submit(GWRPCBus, :url, key)
		end

		if url
			body = [url]
			[200, {'Content-Type'=>'application/text-plain'}, body]
		else
			if sid
				return html_response(404, 'Not Found', "key=`#{key}' sid=#{sid}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
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
		check_request(request, %w[sid conds cols order order_col limit skip])

		# FIXME order
		# FIXME conds

		# TODO
		html_response(501, 'Not Implemented')
	end


	# direct/<rsid>/<sid>/<key>
	#  get(data/key)                          => direct get/gets/read/reads
	def call_direct(env)
		case env['REQUEST_METHOD']
		when 'GET'
			http_direct_get(env)
		else
			return html_response(405, 'Method Not Allowed')
		end
	end

	def http_direct_get(env)
		request = ::Rack::Request.new(env)
		path = get_key_path_info(env)
		rsid_s, sid_s, key = path.split('/', 3)
		rsid = rsid_s.to_i
		sid = sid.to_i
		okey = ObjectKey.new(key, sid, rsid)
		check_request(request, %w[])

		data = submit(DSRPCBus, :get_direct, okey)

		if data
			body = [data]
			[200, {'Content-Type'=>'application/octet-stream'}, body]
		else
			return html_response(404, 'Not Found', "rsid=#{rsid} key=`#{key}' sid=#{sid}")
		end
	end


	private
	def require_str(request, k)
		str = request.GET[k] || request.POST[k]
		unless str
			# FIXME
			raise "#{k} is required"
		end
		str
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
		request.GET[k] || request.POST[k]
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

	def check_request(request, accepts)
		# FIXME check error
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
			return nil
		end
	end

	def format_attrs(attrs, format)
		case format
		when 'json'
			return JSON.dump(attrs), 'application/json'
		when 'msgpack'
			return MessagePack.pack(attrs), 'application/x-msgpack'
		when 'tsv'
			data = attrs.map {|k,v| "#{k}\t#{v}" }.join("\n")
			return data, 'text/tab-separated-values'
		else
			return nil
		end
	end

	def html_response(code, title, msg=nil)
		if msg
			body = ['<html><head></head><body><h1>',
							code.to_s, ' ', title,
							'</h1><p>', CGI.escapeHTML(msg.to_s), "</p></body></html>\r\n"]
		else
			body = ['<html><head></head><body><h1>',
							code.to_s, ' ', title,
							"</h1></body></html>\r\n"]
		end
		return [code, {'Content-Type'=>'text/html'}, body]
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

	def submit(bus, name, *args)
		$log.trace { "http rpc: #{name} #{args}" }

		r = Responder.new

		ProcessBus.submit {
			dispatch(bus, name, args, r)
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

	def dispatch(bus, name, args, r)
		result = bus.__send__(name, *args)
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
