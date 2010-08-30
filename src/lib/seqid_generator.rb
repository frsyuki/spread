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


class SeqidGenerator
	def initialize
		@map = {}   #=> {Symbol => Integer}
		@path = nil
	end

	RESTART_GAP = 10

	def open(path)
		@path = path
	end

	def close
	end

	def next_id(key)
		key = key.to_sym
		if val = @map[key]
			val = @map[key] = val+1
		else
			val = @map[key] = RESTART_GAP
		end
		if val % RESTART_GAP == 0
			write
		end
		val
	end

	private
	def read(path = @path)
		unless File.exist?(path)
			@map = {}
			@path = path
			return
		end

		raw = File.read(path)
		yaml = YAML.load(raw)

		map = {}
		yaml.each_pair {|key,val|
			map[key.to_sym] = val+RESTART_GAP
		}

		@map = map
		@path = path

		nil
	end

	def write(path = @path)
		return nil unless path

		yaml = {}
		@map.each_pair {|key,val|
			yaml[key.to_s] = val
		}

		raw = YAML.dump(yaml)
		File.open(path, 'w') {|f| f.write raw }
		# FIXME flush

		nil
	end
end


end

