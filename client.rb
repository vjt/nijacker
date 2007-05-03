#!/usr/bin/ruby

require 'rubygems'
require 'drb/drb'
require 'lib/mailer'
require 'logger'
require 'benchmark'

class Fixnum
  def minutes; self * 60; end
  alias :minute :minutes
end

class Client
  def initialize
    @uri_list = File.read('config/server.list').split($/)
    @holdtime = 60.minutes / @uri_list.size
    @log = Logger.new File.join('log', 'client.log')
    @log.info "configured #{@uri_list.size} servers, holdtime #{@holdtime}s"

    trap('USR1') { check }
    trap('INT') { graceful_exit }
    trap('TERM') { graceful_exit }
  end

  def run
    catch :mission_accomplished do
      try_every_server_in_list
    end

    fax_thread = Thread.new { deliver_fax }

    each_server do |server, uri|
      @log.info "shutting down #{uri}" 
      server.shutdown
    end

  rescue StandardError => error
    @log.error "unhandled exception: #{error}"

  ensure
    fax_thread.join if fax_thread
    @log.close
    exit
  end

  def check
    each_server do |server, uri|
      begin
        rtt = timeout(5) { Benchmark.measure { server.ping }.real }
        @log.info "reply from #{uri} in #{rtt}s"
      rescue Timeout::Error
        @log.warn "request to #{uri} timed out!"
      end
    end
  end

  def graceful_exit
    @log.warn 'exiting'
    exit
  end

  protected
  def try_every_server_in_list
    loop do
      each_server do |server, uri|
        if server.challenge
          @log.info 'domain is available!'
          throw :mission_accomplished
        end

        @log.info "still trying (last tried: #{uri})"
        sleep @holdtime
      end
      sleep 1 # avoid looping when no servers are available
    end
  end

  def each_server
    @uri_list.each do |uri|
      begin
        yield DRbObject.new_with_uri(uri), uri
      rescue
        @log.warn $!
        next
      end
    end
  end

  def deliver_fax
    @log.info 'trying to deliver fax...'
    Mailer.deliver_fax
    @log.info "SUCCESS!"
  rescue
    @log.warn $!
    sleep 1
    retry
  end

end

if __FILE__ == $0
  fork { Client.new.run }
end
