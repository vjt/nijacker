#!/usr/bin/ruby

require 'drb/drb'
require 'yaml'
require 'facets/core/string/camelize'

conf = ARGV[0] || 'config/nijacker.yml'
config = YAML.load File.read(conf)

$: << 'lib'
require config['handler']
uri = config['listen_on'].freeze
front_object = eval(config['handler'].camelize).new

puts "Listening on #{uri} with a #{front_object.class}"

trap('TERM') { DRb.thread.kill }
DRb.start_service uri, front_object
$SAFE = 1

DRb.thread.join
