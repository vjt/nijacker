require 'socket'
require 'timeout'

class WhoisRequester
  def initialize
    @config = YAML.load File.read('config/whois_requester.yml')
  end

  def challenge
    true if %w(DELETED AVAILABLE).include? domain_status 
  end

  def ping
    'PONG'
  end

  def shutdown
    DRb.stop_service
  end

  def domain_status
    TCPSocket.open(@config['whois_server'], 43) do |sock|
      sock.write @config['whois_domain'] + "\n"
      response = timeout(5) { sock.read }
      response.scan(/Status:\s*([\w_-]+)/).flatten.first
    end
  rescue Errno::ECONNREFUSED
    'REFUSED'
  rescue Timeout::Error
    'TIMEOUT'
  end
end
