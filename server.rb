#!/usr/bin/ruby

require 'drb/drb'
require 'yaml'
require 'facets/core/string/camelize'

config = YAML.load File.read('config/nijacker.yml')

$: << 'lib'
require config['handler']
listen_uri = config['listen_on'].freeze
front_object = eval(config['handler'].camelize).new

DRb.start_service listen_uri, front_object

$SAFE = 1
DRb.thread.join
