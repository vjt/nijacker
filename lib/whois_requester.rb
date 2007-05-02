require 'socket'

class WhoisRequester
  def initialize
    @config = YAML.load File.read('config/whois_requester.yml')
  end

  def challenge
    true if domain_status == 'DELETED'
  end

  def shutdown
    DRb.stop_service
  end

  protected
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
