#!/usr/bin/ruby

require 'drb/drb'

uri_list = File.read('config/server.list').split($/)
puts "configured #{uri_list.size} servers"

DRb.start_service

#loop do
  uri_list.each do |uri|
    server = DRbObject.new_with_uri(uri)
    puts "server at #{uri} says: #{server.test}"
  end
#end
