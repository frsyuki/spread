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


class MemcacheMDS < MDS
	MDSSelector.register(:mc, self)

	class HADB < BasicHADB
		DEFAULT_PORT = 11211

		def open_db(addr)
			MemCache.new(addr.to_s, {:urlencode => false, :compression => :false, :multithread => true, :timeout => 5.0})
		end

		def ensure_db(db, addr)
			true
		end

		def error_result?(db, result)
			nil
		end
	end

	def initialize
		require 'memcache'
	end

	def open(expr)
		@hadb = HADB.new(expr)
	end

	def close
		@hadb.close
	end

	def get_okey(key, version=nil, &cb)
		e = get_impl(key, version)
		if e
			cb.call(e.to_okey(key), nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end
	rescue
		cb.call(nil, $!) rescue nil
	end

	def get_attrs(key, version=nil, &cb)
		e = get_impl(key, version)
		if e
			cb.call(e.attrs, nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end
	rescue
		cb.call(nil, $!) rescue nil
	end

	def get_okey_attrs(key, version=nil, &cb)
		e = get_impl(key, version)
		if e
			cb.call([e.to_okey(key), e.attrs], nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end
	rescue
		cb.call(nil, $!) rescue nil
	end

	def add(key, attrs={}, vname=nil, &cb)
		okey = set_impl(key, attrs, vname)
		cb.call(okey, nil) rescue nil
	rescue
		cb.call(nil, $!) rescue nil
	end

	def update_attrs(key, attrs, &cb)
		okey = update_impl(key) {|old_attrs|
			attrs
		}
		cb.call(okey, nil) rescue nil
	rescue
		cb.call(nil, $!) rescue nil
	end

	def remove(key, &cb)
		e = get_impl(key)

		if e
			result = nil
			@hadb.write(key) {|mc|
				result = mc.delete(key)
			}
			#if result !~ /DELETED/
			# TODO
			#end

			cb.call(e.to_okey(key), nil) rescue nil
		else
			cb.call(nil, nil) rescue nil
		end

	rescue
		cb.call(nil, $!) rescue nil
	end

	private
	class Entry
		def initialize(rsid=nil, vtime=nil, attrs=nil)
			@rsid = rsid
			@vtime = vtime
			@attrs = attrs
		end

		attr_accessor :rsid
		attr_accessor :vtime
		attr_accessor :attrs

		def to_okey(key)
			ObjectKey.new(key, @vtime, @rsid)
		end

		def to_msgpack(out = '')
			[@rsid, @vtime, @attrs].to_msgpack(out)
		end

		def from_msgpack(obj)
			@rsid  = obj[0]
			@vtime = obj[1]
			@attrs = obj[2]
			self
		end
	end

	def get_impl(key, version=nil)
		raise "version is not supported on memcache MDS" if version

		raw = nil
		@hadb.read(key) {|mc|
			raw = mc.get(key, true)
		}

		if raw
			obj = MessagePack.unpack(raw)
			e = Entry.new.from_msgpack(obj)
			return e
		else
			return nil
		end
	end

	def set_impl(key, attrs, vname=nil)
		raise "version is not supported on memcache MDS" if vname

		okey = new_okey(key)
		e = Entry.new(okey.rsid, okey.vtime, attrs)
		raw = e.to_msgpack
		result = nil
		@hadb.write(key) {|mc|
			# TODO add/cas?
			result = mc.set(key, raw, 0, true)
		}

		#if result !~ /STORED/
		# TODO
		#end

		return okey
	end

	def update_impl(key, &modifier)
		e = get_impl(key)

		if e
			e.attrs = modifier.call(e.attrs)
			raw = e.to_msgpack
			@hadb.write(key) {|mc|
				# TODO cas?
				mc.set(key, raw, 0, true)
			}
			return e.to_okey(key)
		else
			return nil
		end
	end
end


end
