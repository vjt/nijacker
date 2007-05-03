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

pid = fork do
  [$stdin, $stdout, $stderr].each { |io| io.close }

  trap('HUP') { }
  trap('TERM') do
    File.delete Pid
    DRb.thread.kill
  end

  DRb.start_service uri, front_object

  Pid = File.join 'log', 'nijacker.pid'
  File.open(Pid, 'w+') do |f|
    f.write "#{$$}\n"
  end

  $SAFE = 1

  DRb.thread.join
end

Process.detach(pid)

puts "daemonized [#{pid}]"
