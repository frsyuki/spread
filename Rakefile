require 'rake'
require 'rake/testtask'
require 'rake/clean'

begin
	require 'jeweler'
	Jeweler::Tasks.new do |gemspec|
		gemspec.name = "spread-osd"
		gemspec.summary = "SpreadOSD - a distributed media storage"
		gemspec.author = "FURUHASHI Sadayuki"
		gemspec.email = "frsyuki@users.sourceforge.jp"
		gemspec.homepage = "http://github.com/frsyuki/spread-osd"
		gemspec.has_rdoc = true
		gemspec.require_paths = ["lib"]
		gemspec.add_dependency "msgpack", ">= 0.4.4"
		gemspec.add_dependency "msgpack-rpc", ">= 0.4.3"
		gemspec.add_dependency "tokyotyrant", ">= 1.13"
		gemspec.test_files = Dir["test/test_*.rb"]
		gemspec.files = Dir["lib/**/*", "ext/**/*", "test/**/*", "spec/**/*", "tasks/**/*"] +
			%w[AUTHORS ChangeLog COPYING NOTICE README.md README.ja.md]
		gemspec.extra_rdoc_files = []
		gemspec.add_development_dependency('rspec')
	end
	Jeweler::GemcutterTasks.new
rescue LoadError
	puts "Jeweler not available. Install it with: gem install jeweler"
end

VERSION_FILE = "lib/spread-osd/version.rb"

file VERSION_FILE => ["VERSION"] do |t|
	version = File.read("VERSION").strip
	File.open(VERSION_FILE, "w") {|f|
		f.write <<EOF
module SpreadOSD

VERSION = '#{version}'

end
EOF
	}
end

task :default => [VERSION_FILE, :build]

task :test => ['test:unit','spec:unit']

