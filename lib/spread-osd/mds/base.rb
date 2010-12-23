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


class MDS
	def self.open(expr)
		if expr =~ /astt:(.*)/
			return AsyncTokyoTyrantMDS.new($~[1])
		elsif expr =~ /tt:(.*)/
			return TokyoTyrantMDS.new($~[1])
		end
		return TokyoTyrantMDS.new(expr)
	end


	# call-seq:
	#   get(key:String, &block) -> block.call(found:Hash or {})
	#
	#def get(key, &block)
	#end

	# call-seq:
	#   set(key:String, map:Hash, &block) -> block.call(success:Boolean)
	#
	#def set(key, map, &block)
	#end

	# call-seq:
	#   remove(key:String, &block) -> block.call(deleted:Hash or {})
	#
	#def remove(key, &block)
	#end
end


end
