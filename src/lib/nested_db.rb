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

require 'tokyocabinet'

module SpreadOSD


class NestedDB
	# key => oid, attributes, [key]
	# key := parent_key \0 key

	class Object
		def initialize(replset=0, oid=nil, attributes={})
			@replset = replset
			@oid = oid
			@attributes = attributes
		end
		attr_accessor :replset
		attr_accessor :oid
		attr_accessor :attributes

		def dump
			[@replset, @attributes, @oid].to_msgpack
		end
		def self.load(raw)
			replset, attributes, oid = MessagePack.unpack(raw)
			self.new(replset, oid, attributes)
		end
	end

	def initialize
		@path = nil
		@db = TokyoCabinet::BDB.new
	end

	def open(path)
		success = @db.open(path, TokyoCabinet::BDB::OWRITER|TokyoCabinet::BDB::OCREAT)
		unless success
			raise "can't open database #{path}: #{@db.errmsg(@db.ecode)}"
		end
		@path = path
	end

	def close
		@db.close
	end

	def set(key, obj)
		val = obj.dump
		success = @db.put(key, val)
		unless success
			raise "failed to put key #{@db.errmsg(@db.ecode)}"
		end
		key
	end

	def set_child(parent_key, key, obj)
		set([parent_key,key].join("\0"), obj)
	end

	def set_attributes(key, attributes)
		if obj = get(key)
			obj.attributes = attributes
			set(key, obj)
			true
		else
			nil
		end
	end

	def get(key)
		val = @db.get(key)
		unless val
			return nil
		end
		Object.load(val)
	end

	def get_child(parent_key, key)
		get([parent_key,key].join("\0"))
	end

	def remove(key)
		if @db.delete(key)
			true
		else
			nil
		end
	end

	def remove_child(parent_key, key)
		remove([parent_key,key].join("\0"))
	end

	def get_child_keys(key, skip=0, limit=5000)
		return [] if limit <= 0

		prefix = "#{key}\0"
		keys = []
		cur = TokyoCabinet::BDBCUR.new(@db)

		success = cur.jump(prefix)
		while success
			key = cur.key

			if key[0, prefix.length] != prefix
				break
			end

			if !key.index("\0", prefix.length) # grandchild
				if skip > 0
					skip -= 1
				else
					keys << key
					if (limit -= 1) <= 0
						break
					end
				end
			end

			success = cur.next
		end

		keys
	end

	def self.join_key(key_seq)
		key_seq.join("\0")
	end

	#def self.parent_key(key)
	#	if index = key.rindex("\0")
	#		key[0,index-1]
	#	else
	#		nil
	#	end
	#end
end


end


if $0 == __FILE__
	require 'rubygems'
	require 'msgpack'

	include SpreadOSD

	def check_equal(o1, o2)
		if o1.class == NestedDB::Object
			if o1.replset != o2.replset|| o1.oid != o2.oid || o1.attributes != o2.attributes
				raise "not match"
			end
		else
			if o1 != o2
				raise "not match"
			end
		end
	end

	db = NestedDB.new
	db.open("nested_db_test.tcb")

	obj1 = NestedDB::Object.new(1, 11, {})
	obj2 = NestedDB::Object.new(1, 12, {})
	obj3 = NestedDB::Object.new(1, 13, {"key"=>"val"})

	db.set("obj1", obj1)
	db.set_child("obj1", "obj2", obj2)
	db.set_child("obj1", "obj3", obj3)

	o1 = db.get("obj1")
	check_equal(obj1, o1)

	keys = db.get_child_keys("obj1")
	check_equal(keys, ["obj1\0obj2", "obj1\0obj3"])

	k2 = keys[0]
	k3 = keys[1]

	o2 = db.get(k2)
	check_equal(o2, obj2)

	o3 = db.get(k3)
	check_equal(o3, obj3)

	success = db.remove("obj1")
	check_equal(true, success)

	success = db.remove(k2)
	check_equal(true, success)

	success = db.remove(k3)
	check_equal(true, success)
end

