#!/usr/bin/ruby

require 'rubygems'
require 'drb/drb'
require 'yaml'
require 'facets/core/string/camelize'

Dir.chdir(File.dirname(__FILE__))

conf = ARGV[0] || 'config/nijacker.yml'
config = YAML.load File.read(conf)

$: << 'lib'
require config['handler']
uri = config['listen_on'].freeze
front_object = eval(config['handler'].camelize).new

Pid = File.join 'log', 'nijacker.pid'
if pid = fork
  puts "daemonized [#{pid}]"
  File.open(Pid, 'w+') do |f|
    f.write "#{pid}\n"
  end
  exit
end

trap('TERM') do
  File.delete Pid
  DRb.thread.kill
end

DRb.start_service uri, front_object
$SAFE = 1

DRb.thread.join
