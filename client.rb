#!/usr/bin/ruby

require 'drb/drb'
require 'lib/mailer'
class Fixnum
  def minutes; self * 60; end
  alias :minute :minutes
end

class Client
  def initialize
    @uri_list = File.read('config/server.list').split($/)
    @holdtime = 30.minutes / @uri_list.size
    puts "configured #{@uri_list.size} servers, holdtime #{@holdtime}s"

    DRb.start_service
  end

  def run
    catch :mission_accomplished do
      try_every_server_in_list
    end

    each_server do |server, uri|
      puts "shutting down #{uri}" 
      server.shutdown
    end

    puts 'delivering FAX...'
    Mailer.deliver_fax
    exit
  end

  protected
  def try_every_server_in_list
    loop do
      each_server do |server, uri|
        if server.challenge
          puts "finished!"
          throw :mission_accomplished
        end

        puts "[#{Time.now}] still trying (last tried: #{uri})"
        sleep @holdtime
      end
    end
  end

  def each_server
    @uri_list.each do |uri|
      yield DRbObject.new_with_uri(uri), uri
    end
  end
end

if __FILE__ == $0
  Client.new.run
end
