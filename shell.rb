#!/usr/bin/ruby

require 'rubygems'
require 'drb/drb'
require 'facets/core/enumerable/to_h'
require 'pp'

$servers = File.read('config/server.list').split($/)

def server(id)
  DRbObject.new_with_uri($servers[id])
end

trap('INT') { puts; exit }

loop do
  begin
    print 'nijacker>> '
    cmd, srv_id, *args = $stdin.readline.split(' ')
    case cmd.to_sym
    when :servers
      pp $servers.to_h
    else
      resp = server(srv_id.to_i).send(cmd.to_sym, *args) || 'nil'
      puts "resp: #{resp}"
    end
  rescue EOFError
    puts
    exit
  rescue
    puts "exception: #{$!}"
  end
end

