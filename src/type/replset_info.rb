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


class ReplsetInfo
	class SetInfo
		def initialize(nids=[])
			@nids = nids
		end

		attr_reader :nids

		def join(nid)
			if @nids.include?(nid)
				return false
			end
			@nids.push(nid)
			true
		end

		def to_s
			"<nids=[#{@nids.join(',')}]>"
		end

		public
		def to_msgpack(out = '')
			[@nids].to_msgpack(out)
		end
		def from_msgpack(obj)
			@nids = obj[0]
			self
		end
	end

	def initialize
		@map = {}  # {rsid => SetInfo}
		@path = nil
		update_hash
	end

	def rebuild(rsid_nids_map)
		map = {}
		rsid_nids_map.each_pair {|rsid,nids|
			info = map[rsid] = SetInfo.new
			nids.each {|nid|
				info.join(nid)
			}
		}
		if @map == map
			return false
		end
		@map = map
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

			nids = s['nids']
			raise "nids field is requred" unless nids

			map[rsid] = SetInfo.new(nids)
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

	def include?(rsid)
		@map.include?(rsid)
	end

	def get_rsids
		@map.keys
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

