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
require 'digest/sha1'

module SpreadOSD


class ReplsetInfo
	class SetInfo
		def initialize(active=false, nids=[])
			@nids = nids
			@active = active
		end

		attr_reader :nids

		def join(nid)
			if @nids.include?(nid)
				return false
			end
			@nids.push(nid)
			true
		end

		def activate!
			if @active
				return false
			end
			@active = true
			true
		end

		def deactivate!
			unless @active
				return false
			end
			@active = false
			true
		end

		def active?
			@active
		end

		def to_s
			"<#{@active ? 'active' : 'inactive'} nids=[#{@nids.join(',')}]>"
		end

		public
		def to_msgpack(out = '')
			[@active, @nids].to_msgpack(out)
		end
		def from_msgpack(obj)
			@active = obj[0]
			@nids = obj[1]
			self
		end
	end

	def initialize
		@map = {}  # {rsid => SetInfo}
		@path = nil
		update_hash
	end

	def read(path)
		unless File.exist?(path)
			@map = {}
			@path = path
			return update_hash
		end

		raw = File.read(path)
		yaml = YAML.load(raw)

		map = {}
		yaml.each {|s|
			rsid = s['id']
			raise "id field is requred" unless rsid

			active = s['active']
			active = false unless active

			nids = s['nids']
			raise "nids field is requred" unless nids

			map[rsid] = SetInfo.new(active, nids)
		}
		@map = map

		@path = path

		update_hash
	end

	def write(path = @path)
		return nil unless path

		yaml = []
		@map.each_pair {|rsid,info|
			yaml.push({
				'id'     => rsid,
				'active' => info.active?,
				'nids'   => info.nids,
			})
		}

		raw = YAML.dump(yaml)
		File.open(path, 'w') {|f| f.write raw }

		true
	end

	def create(rsid)
		unless @map[rsid]
			@map[rsid] = SetInfo.new
			update_hash
			return true
		end
		false
	end

	def join(rsid, nid)
		if info = @map[rsid]
			if info.join(nid)
				update_hash
				return true
			end
		end
		false
	end

	def activate!(rsid)
		if info = @map[rsid]
			if info.activate!
				update_hash
				return true
			end
		end
		false
	end

	def deactivate!(rsid)
		if info = @map[rsid]
			if info.deactivate!
				update_hash
				return true
			end
		end
		false
	end

	def active?(rsid)
		if info = @map[rsid]
			return info.active?
		end
		nil
	end

	def include?(rsid)
		@map.include?(rsid)
	end

	def [](rsid)
		@map[rsid]
	end

	def each(&block)
		@map.each_pair(&block)
	end

	def to_a
		@map.to_a
	end

	def get_hash
		@hash
	end

	def to_s
		"ReplsetInfo #{@map.size} sets [\n" +
			@map.to_a.map{|rsid,info| "  #{rsid}:#{info}\n" }.join +
			"  ] hash=#{@hash.to_s.unpack('C*').map{|c|"%0x"%c}.join}"
	end

	private
	def update_hash
		@hash = Digest::SHA1.digest(to_msgpack)
		nil
	end

	public
	def to_msgpack(out = '')
		@map.to_msgpack(out)
	end
	def from_msgpack(obj)
		map = {}
		obj.each_pair {|k,v|
			map[k] = SetInfo.new.from_msgpack(v)
		}
		@map = map
		update_hash
		self
	end
end


end

