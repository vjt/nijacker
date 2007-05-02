# This is a capistrano recipe.
#
# Pass domain and whois server via ENV['DOMAIN'] and ENV['WHOISSERVER'].
#

# Handy ruby debugger..
#require 'ruby-debug'
#Debugger.start

set :repository, 'https://svn.softmedia.info/opensource/nijacker/trunk'
set :deploy_to, '/tmp/nijacker'
set :deploy_config, 'config/deploy'
set :run_server_as, 'nobody'
role :bot, File.read('config/server.list').scan(/\/\/([\w\d\.]+):/).flatten.uniq

ssh_options[:username] = 'root' # you should change this
ssh_options[:host_key] = 'ssh-dss'

desc <<-DESC
Upload nijacker
DESC
task :deploy, :roles => :bot do
  check_config
  check_credentials
  source.checkout self
  reconfigure
  restart
end

desc <<-DESC
Check that the deploy configuration is correctly in place
DESC
task :check_config, :roles => :bot do
  required = %w(nijacker whois_requester mailer).map { |c| c + '.yml' }
  missing = required - Dir['config/deploy/*.yml']
  unless missing.size.zero?
    missing = missing.map { |f| " - #{f}" }.join(',')
    raise "file(s) missing from #{self[:deploy_config]}: #{missing}"
  end
end

desc <<-DESC
Check that we can run commands with sudo on every host
DESC
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
  Dir['config/deploy/*.yml'].each do |conf|
    put File.read(conf), File.join("#{release_path(releases.last)}", 'config', conf)
  end
  restart
end

desc <<-DESC
Restarts nijacker
DESC
task :restart, :roles => :bot do
  run <<-CMD
    cd #{release_path(releases.last)};
    if [ -r 'log/nijacker.pid' ]; then
      kill -TERM `cat log/nijacker.pid`;
    fi;
  CMD
  sudo "ruby #{release_path(releases.last)}/server.rb", :as => self[:run_server_as]
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
