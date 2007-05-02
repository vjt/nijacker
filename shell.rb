#!/usr/bin/ruby

require 'drb/drb'
require 'facets/core/enumerable/to_h'
require 'pp'

$servers = File.read('config/server.list').split($/)

def server(id)
  DRbObject.new_with_uri($servers[id])
end

trap('INT') { exit }

loop do
  begin
    print 'nijacker>> '
    cmd, srv_id, *ignored = $stdin.readline.split(' ')
    case cmd.to_sym
    when :ping
      puts "resp: " << server(srv_id.to_i).ping
    when :servers
      pp $servers.to_h
    else
      puts 'command unknown'
    end
  rescue EOFError
    exit
  rescue
    puts "exception: #{$!}"
  end
end

