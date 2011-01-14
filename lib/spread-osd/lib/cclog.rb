#
# CCLog
# Copyright (c) 2010 FURUHASHI Sadayuki
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
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

	def on_trace(&block)
		return if @level > LEVEL_TRACE
		block.call if block
	end

	def trace(*args, &block)
		return if @level > LEVEL_TRACE
		args << block.call if block
		msg = args.join
		puts "#{@color_trace}#{caller_line(1,true)}: #{msg}#{@color_reset}"
	end
	alias TRACE trace

	def on_debug(&block)
		return if @level > LEVEL_DEBUG
		block.call if block
	end

	def debug(*args, &block)
		return if @level > LEVEL_DEBUG
		args << block.call if block
		msg = args.join
		puts "#{@color_debug}#{caller_line(1,true)}: #{msg}#{@color_reset}"
	end
	alias DEBUG debug

	def debug_backtrace(backtrace=$!.backtrace)
		return if @level > LEVEL_DEBUG
		backtrace.each {|msg|
			puts "#{@color_debug}#{caller_line(4,true)}: #{msg}#{@color_reset}"
		}
		nil
	end

	def on_info(&block)
		return if @level > LEVEL_INFO
		block.call if block
	end

	def info(*args, &block)
		return if @level > LEVEL_INFO
		args << block.call if block
		msg = args.join
		puts "#{@color_info}#{caller_line(1,true)}: #{msg}#{@color_reset}"
	end
	alias INFO info

	def info_backtrace(backtrace=$!.backtrace)
		return if @level > LEVEL_INFO
		backtrace.each {|msg|
			puts "#{@color_info}#{caller_line(4,true)}: #{msg}#{@color_reset}"
		}
		nil
	end

	def on_warn(&block)
		return if @level > LEVEL_WARN
		block.call if block
	end

	def warn(*args, &block)
		return if @level > LEVEL_WARN
		args << block.call if block
		msg = args.join
		puts "#{@color_warn}#{caller_line(1)}: #{msg}#{@color_reset}"
	end
	alias WARN warn

	def warn_backtrace(backtrace=$!.backtrace)
		return if @level > LEVEL_WARN
		backtrace.each {|msg|
			puts "#{@color_warn}#{caller_line(4)}: #{msg}#{@color_reset}"
		}
		nil
	end

	def on_error(&block)
		return if @level > LEVEL_ERROR
		block.call if block
	end

	def error(*args, &block)
		return if @level > LEVEL_ERROR
		args << block.call if block
		msg = args.join
		puts "#{@color_error}#{caller_line(1)}: #{msg}#{@color_reset}"
	end
	alias ERROR error

	def error_backtrace(backtrace=$!.backtrace)
		return if @level > LEVEL_ERROR
		backtrace.each {|msg|
			puts "#{@color_error}#{caller_line(4)}: #{msg}#{@color_reset}"
		}
		nil
	end

	def on_fatal(&block)
		return if @level > LEVEL_FATAL
		block.call if block
	end

	def fatal(*args, &block)
		return if @level > LEVEL_FATAL
		args << block.call if block
		msg = args.join
		puts "#{@color_fatal}#{caller_line(1)}: #{msg}#{@color_reset}"
	end
	alias FATAL fatal

	def fatal_backtrace(backtrace=$!.backtrace)
		return if @level > LEVEL_FATAL
		backtrace.each {|msg|
			puts "#{@color_fatal}#{caller_line(4)}: #{msg}#{@color_reset}"
		}
		nil
	end

	def puts(msg)
		@out.puts(msg)
		@out.flush
		msg
	rescue
		# FIXME
		nil
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

