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


require 'tokyotyrant'

class TokyoTyrantMDS < MDS
	DEFAULT_PORT = 1978

	def initialize(addrs)
		@rdb = TokyoTyrant::RDBTBL.new
		host, port = addrs.split(':',2)
		port ||= DEFAULT_PORT
		unless @rdb.open(host, port)
			raise "failed to open TokyoTyrant MDS: #{@rdb.errmsg(@rdb.ecode)}"
		end
	end

	def close
		@rdb.close
	end

	def get(key, &block)
		map = @rdb.get(key)
		map ||= {}
		block.call(map)
		nil
	end

	def set(key, map, &block)
		success = @rdb.put(key, map)
		block.call(success)
		nil
	end

	def remove(key, &block)
		map = @rdb.get(key)
		if map
			@rdb.out(key)
		else
			map = {}
		end
		block.call(map)
		nil
	end

	#def add_or_get(key, map, &block)
	#	success = @rdb.putkeep(key, map)
	#	if success
	#		block.call(nil)
	#	else
	#		map = @rdb.get(key)
	#		map ||= {}
	#		block.call(map)
	#	end
	#	nil
	#end

	#def atomic(key, modproc, &block)
	#	success = nil
	#	while true
	#		map = @rdb.get(key)
	#		map ||= {}
	#		nmap = modproc.call(map)
	#		# TODO Tokyo Tyrant doesn't support CAS?
	#		success = @rdb.put(key, nmap)
	#		break
	#	end
	#	block.call(success)
	#end

	#def select(conds, columns, order, limit, skip, &block)
	#end

	#def count(conds, &block)
	#end
end


end
