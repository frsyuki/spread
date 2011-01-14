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


class FileRelayTimeStampService < RelayTimeStampService
	RelayTimeStampSelector.register(:file, self)

	def init(expr)
		@dir = expr
	end

	class Stamp
		include RelayTimeStamp

		def initialize(path)
			@path = path
			@tmp_path = "#{@path}.tmp"
			@file = nil
		end

		def close
			if @file
				@file.close
				@file = nil
			end
			nil
		end

		def get
			unless @file
				@file = File.open(@path)
			end
			@file.pos = 0
			@file.read.to_i
		rescue
			0
		end

		def set(pos, &block)
			close

			File.open(@tmp_path, "w") {|f|
				f.write(pos.to_s)
			}

			block.call if block

			File.rename(@tmp_path, @path)

			nil
		end
	end

	def open(nid)
		Stamp.new("#{@dir}/rts-#{nid}")
	end
end


end
