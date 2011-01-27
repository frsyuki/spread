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


class DataServerURLService < Service
	# %p    path encoded key
	# %k    url encoded key
	# %s    sid
	# %r    rsid
	def initialize
		host = ConfigBus.self_address.host
		if redirect_http_port = ConfigBus.http_redirect_port
			if redirect_http_path_format = ConfigBus.http_redirect_path_format
				@format = "http://#{host}:#{redirect_http_port}/#{redirect_http_path_format}"
				@format << '%p' unless @format.include?('%')
			else
				@format = "http://#{host}:#{redirect_http_port}/%p"
			end

		elsif self_http_address = ConfigBus.http_gateway_address
			@format = "http://#{host}:#{self_http_address.port}/direct/%r/%s/%k"

		else
			@format = nil
		end
	end

	def rpc_url_direct(okey)
		unless @format
			raise "redirect url is not configured"
		end

		unless StorageBus.exist(okey.sid, okey.key)
			return nil
		end

		format_url(okey)
	end

	ebus_connect :DSRPCBus,
		:url_direct => :rpc_url_direct

	private
	def format_url(okey)
		url = @format.dup

		url.gsub!('%s', okey.sid.to_s)
		url.gsub!('%r', okey.rsid.to_s)

		path_key_index = url.index('%p')
		url_key_index = url.index('%k')

		if path_key_index
			path_key = DirectoryStorageService.encode_okey(okey)
			url[path_key_index,2] = path_key
		end
		if url_key_index
			url_key = CGI.escape(okey.key)
			url[url_key_index,2] = url_key
		end

		url
	end
end


end
