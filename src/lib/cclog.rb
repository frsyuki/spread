#
#  CCLog
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

class CCLog
	module TTYColor
		RESET   = "\033]R"
		CRE     = "\033[K"
		CLEAR   = "\033c"
		NORMAL  = "\033[0;39m"
		RED     = "\033[1;31m"
		GREEN   = "\033[1;32m"
		YELLOW  = "\033[1;33m"
		BLUE    = "\033[1;34m"
		MAGENTA = "\033[1;35m"
		CYAN    = "\033[1;36m"
		WHITE   = "\033[1;37m"
	end

	LEVEL_TRACE = 0
	LEVEL_DEBUG = 1
	LEVEL_INFO  = 2
	LEVEL_WARN  = 3
	LEVEL_ERROR = 4
	LEVEL_FATAL = 5

	def initialize(level = LEVEL_TRACE, out = $stdout)
		if out.tty?
			enable_color
		else
			disable_color
		end
		@level = level
		@out = out
	end

	def enable_color
		@color_trace = TTYColor::BLUE
		@color_debug = TTYColor::WHITE
		@color_info  = TTYColor::GREEN
		@color_warn  = TTYColor::YELLOW
		@color_error = TTYColor::MAGENTA
		@color_fatal = TTYColor::RED
		@color_reset = TTYColor::NORMAL
	end

	def disable_color
		@color_trace = ''
		@color_debug = ''
		@color_info  = ''
		@color_warn  = ''
		@color_error = ''
		@color_fatal = ''
		@color_reset = ''
	end

	attr_accessor :out
	attr_accessor :level

	def trace(*args, &block)
		return if @level > LEVEL_TRACE
		args << block.call if block
		msg = args.join
		puts "#{@color_trace}#{caller_line(1,true)}: #{msg}#{@color_reset}"
	end
	alias TRACE trace

	def debug(*args, &block)
		return if @level > LEVEL_DEBUG
		args << block.call if block
		msg = args.join
		puts "#{@color_debug}#{caller_line(1,true)}: #{msg}#{@color_reset}"
	end
	alias DEBUG debug

	def info(*args, &block)
		return if @level > LEVEL_INFO
		args << block.call if block
		msg = args.join
		puts "#{@color_info}#{caller_line(1,true)}: #{msg}#{@color_reset}"
	end
	alias INFO info

	def warn(*args, &block)
		return if @level > LEVEL_WARN
		args << block.call if block
		msg = args.join
		puts "#{@color_warn}#{caller_line(1)}: #{msg}#{@color_reset}"
	end
	alias WARN warn

	def error(*args, &block)
		return if @level > LEVEL_ERROR
		args << block.call if block
		msg = args.join
		puts "#{@color_error}#{caller_line(1)}: #{msg}#{@color_reset}"
	end
	alias ERROR error

	def fatal(*args, &block)
		return if @level > LEVEL_FATAL
		args << block.call if block
		msg = args.join
		puts "#{@color_fatal}#{caller_line(1)}: #{msg}#{@color_reset}"
	end
	alias FATAL fatal

	def puts(msg)
		@out.puts(msg)
		@out.flush
		msg
	end

	private
	def caller_line(level, debug = false)
		line = caller(level+1)[0]
		if match = /^(.+?):(\d+)(?::in `(.*)')?/.match(line)
			if debug
				"#{match[1]}:#{match[2]}:#{match[3]}"
			else
				"#{match[1]}:#{match[2]}"
			end
		else
			""
		end
	end
end

