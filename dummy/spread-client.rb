require 'msgpack/rpc'


class SpreadClient < MessagePack::RPC::Client::Base
	def initialize(*args)
		super
	end

	def add(path, attributes, data)
		@base.call(:add, path, attributes, data)
	end

	def add_async(path, attributes, data)
		@base.call_async(:add, path, attributes, data)
	end


	def get(path)
		@base.call(:get, path)
	end

	def get_async(path)
		@base.call_async(:get, path)
	end


	def get_attributes(path)
		@base.call(:get_attributes, path)
	end

	def get_attributes_async(path)
		@base.call(:get_attributes_async, path)
	end


	def set_attributes(path, attributes)
		@base.call(:set_attributes, path, attributes)
	end

	def set_attributes_async(path, attributes)
		@base.call(:set_attributes_async, path, attributes)
	end


	def get_direct(mid)
		@base.call(:get_direct, mid)
	end

	def get_direct_async(mid)
		@base.call(:get_direct_async, mid)
	end


	def get_child_keys(path, skip, limit)
		@base.call(:get_child_keys, path, skip, limit)
	end

	def get_child_keys_async(path, skip, limit)
		@base.call(:get_child_keys_async, path, skip, limit)
	end


	private
	def check_type(name, obj, klass)
		unless obj.is_a?(klass)
			raise "#{name} must be a #{klass}"
		end
	end
end

