# This is a capistrano recipe.
#
# Pass domain and whois server via ENV['DOMAIN'] and ENV['WHOISSERVER'].
#

# Handy ruby debugger..
#require 'ruby-debug'
#Debugger.start

set :repository, 'https://svn.softmedia.info/opensource/nijacker/trunk'
set :deploy_to, '/tmp/nijacker'
set :run_server_as, 'nobody'
role :bot, File.read('config/server.list').scan(/\/\/([\w\d\.]+):/).flatten.uniq

ssh_options[:username] = 'root' # you should change this
ssh_options[:host_key] = 'ssh-dss'

desc <<-DESC
Upload nijacker
DESC
task :deploy, :roles => :bot do
  source.checkout self
  reconfigure
  restart
end

task :check_credentials, :roles => :bot do
  sudo 'uname -a', :as => self[:deploy_user]
end

desc <<-DESC
Remove nijacker
DESC
task :uninstall, :roles => :bot do
  run "rm -rf #{self[:deploy_to]}"
end

desc <<-DESC
Change configuration (via DOMAIN and WHOISSERVER passed via the environment)
Invokes a restart.
DESC
task :reconfigure, :roles => :bot do
  req_vars = %w(DOMAIN WHOISSERVER)
  unless req_vars.all? { |k| ENV.has_key? k }
    raise req_vars.join(' or ') + ' were not passed via environment!'
  end

  config = File.read(File.join('config', 'whois_requester.yml.template'))
  config.sub! '@@WHOIS_SERVER@@', ENV['WHOISSERVER']
  config.sub! '@@WHOIS_DOMAIN@@', ENV['DOMAIN']
  put config, "#{release_path}/config/whois_requester.yml"

  restart
end

desc <<-DESC
Restarts nijacker
DESC
task :restart, :roles => :bot do
  def last_release_path
    File.join self[:deploy_to], 'releases', releases.last
  end

  run <<-CMD
    cd #{last_release_path};
    if [ -r 'log/nijacker.pid' ]; then
      kill -TERM `cat log/nijacker.pid`;
    fi;
  CMD
  sudo "ruby #{last_release_path}/server.rb", :as => self[:run_server_as]
end

# a bug in net-ssh is annoying me, so this is a dirty hack that fixes the 
# effect on the fly every time. yes, i should have debugged. but i'm lazy.
# and i want to be on time.
at_exit do
  File.open(File.join(ENV['HOME'], '.ssh', 'known_hosts'), 'r+') do |file|
    kh = file.read.split("\n")
    if kh.last =~ /^\s*ssh-.*/
      kh.pop 
      file.rewind
      file.truncate 0
      file.write kh.join("\n") << "\n"
    end
  end
end
