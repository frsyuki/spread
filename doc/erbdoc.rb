#!/usr/bin/env ruby

require 'rubygems'
require 'erb'
require 'bluecloth'

out = ARGV[1]
md = File.read(ARGV[0])
erb = File.read(File.dirname(__FILE__)+"/doc.erb")

bc = BlueCloth.new(md)
body = bc.to_html

if m = /\<h1[^\>]*\>(.*)\<\/h1\>/.match(body)
	title = m[1]
else
	title = ARGV[0]
end

body.gsub!(/href=\"(:?doc\/)?([^\/]*)\.md\"/, 'href="\2.html"')

result = ERB.new(erb).result
File.open(out, "w") {|f|
	f.write(result)
}

