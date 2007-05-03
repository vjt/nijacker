require 'socket'

class WhoisServer
  include Socket::Constants

  def initialize
    @sock = TCPServer.new(43)
    trap('TERM') { exit }
  end

  def run
    loop do
      client, client_addr = @sock.accept
      request = client.readline
      client.write answer(request)
      client.close
    end
  end

  protected
  def answer(domain)
    text = File.read 'config/fake_whois_answer.txt'
    text.sub! '@@DOMAIN@@', domain
    text.sub! '@@STATUS@@', (rand(6) != 3) ? 'ACTIVE' : 'DELETED'
  end
end

if __FILE__ == $0
  WhoisServer.new.run
end
