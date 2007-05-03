# This is a capistrano recipe.
#
# Pass domain and whois server via ENV['DOMAIN'] and ENV['WHOISSERVER'].
#

# Handy ruby debugger..
#require 'ruby-debug'
#Debugger.start

set :repository, 'https://svn.softmedia.info/opensource/nijacker/branches/server'
set :deploy_to, '/usr/local/nijacker'
set :deploy_config, 'config/deploy'
set :run_server_as, 'nobody'
role :bot, *File.read('config/server.list').scan(/\/\/([\w\d\.]+):/).flatten.uniq

ssh_options[:username] = 'root' # you should change this
ssh_options[:host_key] = 'ssh-dss'
ssh_options[:paranoid] = false

desc <<-DESC
Deploy nijacker
DESC
task :deploy, :roles => :bot do
  check_config
  check_credentials
  check_out_tha_source
  upload_config
  restart
end

desc <<-DESC
Check required rubygems
DESC
task :install_rubygems, :roles => :bot do
  sudo "gem install -y --no-rdoc --no-ri actionmailer facets"
end

desc <<-DESC
Check that the deploy configuration is correctly in place
DESC
task :check_config, :roles => :bot do
  required = %w(nijacker whois_requester).map { |c| c + '.yml' }
  missing = required - Dir['config/deploy/*.yml'].map { |c| File.basename(c) }
  unless missing.empty?
    missing = missing.map { |f| " - #{f}" }.join(',')
    raise "file(s) missing from #{self[:deploy_config]}: #{missing}"
  end
end

desc <<-DESC
Check that we can run commands with sudo on every host
DESC
task :check_credentials, :roles => :bot do
  sudo 'uname -a'
end

desc <<-DESC
Check out tha fscking source!
DESC
task :check_out_tha_source, :roles => :bot do
  set :rel_to_stop, releases.last

  source.checkout self
  sudo "chmod 1777 #{release_path(releases.last)}/log"
end

desc <<-DESC
Remove nijacker
DESC
task :uninstall, :roles => :bot do
  stop
  run "rm -rf #{self[:deploy_to]}"
end

desc <<-DESC
Upload configuration.
DESC
task :upload_config, :roles => :bot do
  Dir['config/deploy/*.yml'].each do |conf|
    put File.read(conf), "#{release_path(releases.last)}/#{conf.sub('deploy/', '')}", :mode => 0644
  end
end

desc <<-DESC
Show status on each remote server
DESC
task :status, :roles => :bot do
  run 'ps axuw | grep ^nobody.*nijack'
end

desc <<-DESC
Stops nijacker
DESC
task :stop, :roles => :bot do
  rel_to_stop = self[:rel_to_stop] || releases.last

  run <<-CMD
    cd #{release_path(rel_to_stop)};
    if [ -r 'log/nijacker.pid' ]; then
      kill -TERM `cat log/nijacker.pid` && sleep 1 || true;
    fi;
  CMD
end

desc <<-DESC
Starts nijacker
DESC
task :start, :roles => :bot do
  sudo "ruby #{release_path(releases.last)}/server.rb", :as => self[:run_server_as]
end

desc <<-DESC
Restarts nijacker
DESC
task :restart, :roles => :bot do
  stop
  start
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
