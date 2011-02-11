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
		require 'erb'
		require 'json'
		require 'thread'
		instance.init(ConfigBus.http_gateway_address, ConfigBus.http_gateway_error_template_file)
	end

	DEFAULT_FORMAT = 'json'

	DEFAULT_TEMPLATE =<<EOF
<html>
<head>
<title><%= code %> <%= title %></title>
</head>
<body>
<center><h1><%= code %> <%= title %></h1></center>
<hr>
<center>SpreadOSD <%= SpreadOSD::VERSION %></center>
</body>
</html>
EOF

	def initialize
		@thread = nil
		@server = nil
	end

	def init(addr, tmplfile)
		if tmplfile
			erb = File.read(tmplfile)
		else
			erb = DEFAULT_TEMPLATE
		end
		@erb = ERB.new(erb)

		opt = {
			:BindAddress => addr.host,
			:Port => addr.port,
		}
		@server = ::WEBrick::HTTPServer.new(opt)
		me = self

		app = ::Rack::URLMap.new({
			'/data'     => Proc.new {|env| me.call_data(env)     },
			'/attrs'    => Proc.new {|env| me.call_attrs(env)    },
			'/api'      => Proc.new {|env| me.call_rpc(env)      },
			'/direct'   => Proc.new {|env| me.call_direct(env)   },
			'/redirect' => Proc.new {|env| me.call_redirect(env) },
		})

		@server.mount("/", ::Rack::Handler::WEBrick, app)
		@thread = Thread.new do
			@server.start
		end
	end

	# data/<key>
	#  get(data/key)         => get_data
	#     vtime=i            => gett_data
	#     vname=s            => getv_data
	# post(data/key, data)   => add_data
	#     vname=s            => addv_data
	#     attrs=formated     => add/addv
	#     format=json/msgpack/tsv
	#  put(data/key, data)   => add_data
	#     vname=s            => addv_data
	#     attrs=formated     => add/addv
	#     format=json/msgpack/tsv
	# TODO delete(data/key)
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
		vtime = optional_int(request, 'vtime')
		if vtime
			check_request(request, %w[vtime])
		else
			vname = optional_str(request, 'vname')
			check_request(request, %w[vname])
		end

		if vtime
			data = submit(GWRPCBus, :gett_data, vtime, key)
		elsif vname
			data = submit(GWRPCBus, :getv_data, vname, key)
		else
			data = submit(GWRPCBus, :get_data, key)
		end

		if data
			body = [data]
			return [200, {'Content-Type'=>'application/octet-stream'}, body]
		else
			if vtime
				return html_response(404, 'Not Found', "key=`#{key}' vtime=#{vtime}")
			elsif vname
				return html_response(404, 'Not Found', "key=`#{key}' vname=#{vname}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_data_post(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		data = require_str(request, 'data')
		vname = optional_str(request, 'vname')
		attrs = optional_str(request, 'attrs')
		if attrs
			format = optional_str(request, 'format')
			format ||= DEFAULT_FORMAT
			check_request(request, %w[data vname attrs format])
		else
			check_request(request, %w[data vname])
		end

		if attrs
			attrs = parse_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			if vname
				okey = submit(GWRPCBus, :addv, vname, key, data, attrs)
			else
				okey = submit(GWRPCBus, :add, key, data, attrs)
			end
		else
			if vname
				okey = submit(GWRPCBus, :addv_data, vname, key, data)
			else
				okey = submit(GWRPCBus, :add_data, key, data)
			end
		end

		# FIXME return okey?
		return html_response(200, 'OK')
	end

	def http_data_put(env)
		if env['HTTP_EXPECT'] == '100-continue'
			return html_response(417, 'Exception Failed')
		end

		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		vname = optional_str(request, 'vname')
		attrs = optional_str(request, 'attrs')
		if attrs
			format = optional_str(request, 'format')
			format ||= DEFAULT_FORMAT
			check_request(request, %w[vname attrs format])
		else
			check_request(request, %w[vname])
		end

		data = env['rack.input'].read

		if attrs
			attrs = parse_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			if vname
				okey = submit(GWRPCBus, :addv, vname, key, data, attrs)
			else
				okey = submit(GWRPCBus, :add, key, data, attrs)
			end
		else
			if vname
				okey = submit(GWRPCBus, :addv_data, vname, key, data)
			else
				okey = submit(GWRPCBus, :add_data, key, data)
			end
		end

		# FIXME return okey?
		return html_response(202, 'Accepted')
	end


	# attrs/<key>
	#  get(data/key)         => get_attrs
	#     vtime=i            => gett_attrs
	#     vname=s            => getv_attrs
	#     format=json/msgpack/tsv
	# post(attrs/key, json)  => update_attrs
	#  put(attrs/key, json)  => update_attrs
	# TODO delete(data/key)
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
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		vtime = optional_int(request, 'vtime')
		if vtime
			check_request(request, %w[format vtime])
		else
			vname = optional_str(request, 'vname')
			check_request(request, %w[format vname])
		end

		if vtime
			attrs = submit(GWRPCBus, :gett_attrs, vtime, key)
		elsif vname
			attrs = submit(GWRPCBus, :getv_attrs, vname, key)
		else
			attrs = submit(GWRPCBus, :get_attrs, key)
		end

		if attrs
			attrs, ct = format_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			body = [attrs]
			return [200, {'Content-Type'=>ct}, body]
		else
			if vtime
				return html_response(404, 'Not Found', "key=`#{key}' vtime=#{vtime}")
			elsif vname
				return html_response(404, 'Not Found', "key=`#{key}' vname=#{vname}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_attrs_post(env)
		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		attrs = require_str(request, 'attrs')
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[attrs format])

		attrs = parse_attrs(attrs, format)
		unless attrs
			return html_response(400, 'Bad Request', "unknown format `#{format}'")
		end

		okey = submit(GWRPCBus, :update_attrs, key, attrs)

		if okey
			return html_response(200, 'OK')
		else
			return html_response(404, 'Not Found', "key=`#{key}'")
		end
	end

	def http_attrs_put(env)
		if env['HTTP_EXPECT'] == '100-continue'
			return html_response(417, 'Exception Failed')
		end

		request = ::Rack::Request.new(env)
		key = get_key_path_info(env)
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[format])

		attrs = env['rack.input'].read
		attrs = parse_attrs(attrs, format)
		unless attrs
			return html_response(400, 'Bad Request', "unknown format `#{format}'")
		end

		okey = submit(GWRPCBus, :update_attrs, key, attrs)

		if okey
			return html_response(202, 'Accepted')
		else
			return html_response(404, 'Not Found', "key=`#{key}'")
		end
	end


	# redirect/<key>
	#  get(data/key)         => url
	#     vtime=i            => urlt
	#     vname=s            => urlv
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
		vtime = optional_int(request, 'vtime')
		if vtime
			check_request(request, %w[vtime])
		else
			vname = optional_str(request, 'vname')
			check_request(request, %w[vname])
		end

		if vtime
			url = submit(GWRPCBus, :urlt, vtime, key)
		elsif vname
			url = submit(GWRPCBus, :urlv, vname, key)
		else
			url = submit(GWRPCBus, :url, key)
		end

		if url
			body = [url]
			return [302, {'Content-Type'=>'text/plain', 'Location'=>url}, body]
		else
			if vtime
				return html_response(404, 'Not Found', "key=`#{key}' vtime=#{vtime}")
			elsif vname
				return html_response(404, 'Not Found', "key=`#{key}' vname=#{vname}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end


	# api/<cmd>
	#  get(api/cmd?k=v)
	# post(api/cmd?k=v)
	#    cmd:
	#      get_data      key= [vtime=] [vname=]
	#      get_attrs     key= [vtime=] [vname=] [format=]
	#      add           key= [vname=] data= [attrs= [format=]]
	#      add_data      (alias of add)
	#      update_attrs  key= attrs= [format=]
	#      remove        key=
	#      url           key= [vtime=] [vname=]
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
		when 'add'
			http_rpc_add(env)
		when 'add_data'
			http_rpc_add(env)
		when 'update_attrs'
			http_rpc_update_attrs(env)
		when 'remove'
			http_rpc_remove(env)
		when 'url'
			http_rpc_url(env)
		else
			return html_response(406, 'Not Acceptable Method')
		end
	end

	def http_rpc_get_data(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		vtime = optional_int(request, 'vtime')
		if vtime
			check_request(request, %w[key vtime])
		else
			vname = optional_str(request, 'vname')
			check_request(request, %w[key vname])
		end

		if vtime
			data = submit(GWRPCBus, :gett_data, vtime, key)
		elsif vname
			data = submit(GWRPCBus, :getv_data, vname, key)
		else
			data = submit(GWRPCBus, :get_data, key)
		end

		if data
			body = [data]
			return [200, {'Content-Type'=>'application/octet-stream'}, body]
		else
			if vtime
				return html_response(404, 'Not Found', "key=`#{key}' vtime=#{vtime}")
			elsif vname
				return html_response(404, 'Not Found', "key=`#{key}' vname=#{vname}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_rpc_get_attrs(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		vtime = optional_int(request, 'vtime')
		if vtime
			check_request(request, %w[format vtime])
		else
			vname = optional_str(request, 'vname')
			check_request(request, %w[format vname])
		end

		if vtime
			attrs = submit(GWRPCBus, :gett_attrs, vtime, key)
		elsif vname
			attrs = submit(GWRPCBus, :getv_attrs, vname, key)
		else
			attrs = submit(GWRPCBus, :get_attrs, key)
		end

		if attrs
			attrs, ct = format_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			body = [attrs]
			return [200, {'Content-Type'=>ct}, body]
		else
			if vtime
				return html_response(404, 'Not Found', "key=`#{key}' vtime=#{vtime}")
			elsif vname
				return html_response(404, 'Not Found', "key=`#{key}' vname=#{vname}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end

	def http_rpc_add(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		data = require_str(request, 'data')
		vname = optional_str(request, 'vname')
		attrs = optional_str(request, 'attrs')
		if attrs
			format = optional_str(request, 'format')
			format ||= DEFAULT_FORMAT
			check_request(request, %w[key vname data attrs format])
		else
			check_request(request, %w[key vname data])
		end

		if attrs
			attrs = parse_attrs(attrs, format)
			unless attrs
				return html_response(400, 'Bad Request', "unknown format `#{format}'")
			end
			if vname
				okey = submit(GWRPCBus, :addv, vname, key, data, attrs)
			else
				okey = submit(GWRPCBus, :add, key, data, attrs)
			end
		else
			if vname
				okey = submit(GWRPCBus, :addv_data, vname, key, data)
			else
				okey = submit(GWRPCBus, :add_data, key, data)
			end
		end

		# FIXME return okey?
		return html_response(200, 'OK')
	end

	def http_rpc_update_attrs(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		attrs = require_str(request, 'attrs')
		format = optional_str(request, 'format')
		format ||= DEFAULT_FORMAT
		check_request(request, %w[attrs format])

		attrs = parse_attrs(attrs, format)
		unless attrs
			return html_response(400, 'Bad Request', "unknown format `#{format}'")
		end

		okey = submit(GWRPCBus, :update_attrs, key, attrs)

		if okey
			return html_response(200, 'OK')
		else
			return html_response(404, 'Not Found', "key=`#{key}'")
		end
	end

	def http_rpc_remove(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		check_request(request, %w[key])

		removed = submit(GWRPCBus, :remove, key)

		if removed
			return html_response(200, 'OK')
		else
			return html_response(404, 'Not Found', "key=`#{key}'")
		end
	end

	def http_rpc_url(env)
		request = ::Rack::Request.new(env)
		key = require_str(request, 'key')
		vtime = optional_int(request, 'vtime')
		if vtime
			check_request(request, %w[key vtime])
		else
			vname = optional_str(request, 'vname')
			check_request(request, %w[key vname])
		end

		if vtime
			url = submit(GWRPCBus, :urlt, vtime, key)
		elsif vname
			url = submit(GWRPCBus, :urlv, vname, key)
		else
			url = submit(GWRPCBus, :url, key)
		end

		if url
			body = [url]
			return [200, {'Content-Type'=>'text/plain'}, body]
		else
			if vtime
				return html_response(404, 'Not Found', "key=`#{key}' vtime=#{vtime}")
			elsif vname
				return html_response(404, 'Not Found', "key=`#{key}' vname=#{vname}")
			else
				return html_response(404, 'Not Found', "key=`#{key}'")
			end
		end
	end


	# direct/<rsid>/<vtime>/<key>  => get_direct
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
		rsid, vtime, key = path.split('/', 3)
		rsid = rsid.to_i
		vtime = vtime.to_i

		check_request(request, %w[])

		okey = ObjectKey.new(key, vtime, rsid)
		data = submit(DSRPCBus, :get_direct, okey)

		if data
			body = [data]
			return [200, {'Content-Type'=>'application/octet-stream'}, body]
		else
			return html_response(404, 'Not Found', "rsid=#{rsid} key=`#{key}' vtime=#{vtime}")
		end
	end


	private
	def require_str(request, k)
		str = request.GET[k] || request.POST[k]
		unless str
			# FIXME HTTP error code
			raise "#{k} is required"
		end
		str
	end

	def require_int(request, k)
		str = require_str(request, k)
		# FIXME check error
		str.to_i
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
		body = @erb.result(SpreadOSD.HTTPGatewayService_get_binding(code, title, msg))
		return [code, {'Content-Type'=>'text/html'}, [body]]
		#if msg
		#	body = ['<html><head></head><body><h1>',
		#					code.to_s, ' ', title,
		#					'</h1><p>', CGI.escapeHTML(msg.to_s), "</p></body></html>\r\n"]
		#else
		#	body = ['<html><head></head><body><h1>',
		#					code.to_s, ' ', title,
		#					"</h1></body></html>\r\n"]
		#end
		#return [code, {'Content-Type'=>'text/html'}, body]
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
		$log.trace { "http api: #{name} #{args}" }

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
		msg = ["http api error on #{name}: #{e}"]
		e.backtrace.each {|bt| msg <<  "    #{bt}" }
		$log.error msg.join("\n")
		r.error(e)
	end
end


def self.HTTPGatewayService_get_binding(code, title, message)
	binding
end


end
