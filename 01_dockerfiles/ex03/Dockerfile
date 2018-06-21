FROM debian:latest
# run as root!
RUN apt-get update -y && apt-get upgrade -y && apt-get install sudo -y
# Install the required packages (needed to compile Ruby and native extensions to Ruby gems)
RUN sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake
# Install Git
RUN sudo apt-get install -y git-core
# Ruby interpreter is required to run GitLab
RUN sudo apt-get remove ruby1.8 && mkdir /tmp/ruby && cd /tmp/ruby && curl --remote-name --progress https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.4.tar.gz && echo 'ec82b0d53bd0adad9b19e6b45e44d54e9ec3f10c  ruby-2.4.4.tar.gz' | shasum -c - && tar xzf ruby-2.4.4.tar.gz && cd ruby-2.4.4
RUN ./configure --disable-install-rdoc && make && sudo make install
# install the Bundler gem
RUN sudo gem install bundler --no-ri --no-rdoc
# Remove former Go installation folder
RUN sudo rm -rf /usr/local/go && curl --remote-name --progress https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz && echo '1862f4c3d3907e59b04a757cfda0ea7aa9ef39274af99a784f5be843c80c6772  go1.8.3.linux-amd64.tar.gz' | shasum -a256 -c - &&   sudo tar -C /usr/local -xzf go1.8.3.linux-amd64.tar.gz && sudo ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/ && rm go1.8.3.linux-amd64.tar.gz
# install node v8.x
RUN curl --location https://deb.nodesource.com/setup_8.x | sudo bash - && sudo apt-get install -y nodejs && curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && sudo apt-get update && sudo apt-get install yarn
# Create a git user for GitLab
RUN sudo adduser --disabled-login --gecos 'GitLab' git
# Install the database packages
RUN sudo apt-get install -y postgresql postgresql-client libpq-dev postgresql-contrib
# Create a database user for GitLab
RUN sudo -u postgres psql -d template1 -c "CREATE USER git CREATEDB;"
# Create the pg_trgm extension (required for GitLab 8.6+)
RUN sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
# Create the GitLab production database and grant all privileges on database
RUN sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
# connecting to the new database with the new user
RUN sudo -u git -H psql -d gitlabhq_production && gitlabhq_production> \q
# install Redis 2.8
RUN sudo apt-get install redis-server
# We'll install GitLab into home directory of the user "git"
RUN cd /home/git
# Clone GitLab repository
RUN sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 11-0-stable gitlab
# Go to GitLab installation folder
RUN cd /home/git/gitlab
# Copy the example GitLab config
RUN sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
# Update GitLab config file, follow the directions at top of file
RUN sudo -u git -H editor config/gitlab.yml
# Copy the example secrets file
RUN sudo -u git -H cp config/secrets.yml.example config/secrets.yml && sudo -u git -H chmod 0600 config/secrets.yml
# Make sure GitLab can write to the log/ and tmp/ directories
RUN sudo chown -R git log/ && sudo chown -R git tmp/ && sudo chmod -R u+rwX,go-w log/ && sudo chmod -R u+rwX tmp/
# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
RUN sudo chmod -R u+rwX tmp/pids/ && sudo chmod -R u+rwX tmp/sockets/
# Create the public/uploads/ directory
RUN sudo -u git -H mkdir public/uploads/
# Make sure only the GitLab user has access to the public/uploads/ directory
# now that files in public/uploads are served by gitlab-workhorse
RUN sudo chmod 0700 public/uploads
# Change the permissions of the directory where CI job traces are stored
RUN sudo chmod -R u+rwX builds/
# Change the permissions of the directory where CI artifacts are stored
RUN sudo chmod -R u+rwX shared/artifacts/
# Change the permissions of the directory where GitLab Pages are stored
RUN sudo chmod -R ug+rwX shared/pages/
# Copy the example Unicorn config
RUN sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb
# Copy the example Rack attack config
RUN sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb
# Configure Git global settings for git user
# 'autocrlf' is needed for the web editor
RUN sudo -u git -H git config --global core.autocrlf input
# Disable 'git gc --auto' because GitLab already runs 'git gc' when needed
RUN sudo -u git -H git config --global gc.auto 0
# Enable packfile bitmaps
RUN sudo -u git -H git config --global repack.writeBitmaps true
# Enable push options
RUN sudo -u git -H git config --global receive.advertisePushOptions true
# Configure Redis connection settings
RUN sudo -u git -H cp config/resque.yml.example config/resque.yml
# Configure GitLab DB Settings
RUN sudo -u git cp config/database.yml.postgresql config/database.yml
# Make config/database.yml readable to git only
RUN sudo -u git -H chmod o-rwx config/database.yml
# Install gems
RUN sudo -u git -H bundle install --deployment --without development test mysql aws kerberos
# Run the installation task for gitlab-shell
RUN sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true
# Install gitlab-workhorse
RUN sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production && printf 'yes\n'
# Initialize Database and Activate Advanced Features
RUN sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
# Type 'yes' to create the database tables.
# When done you see 'Administrator account created:'
# Install Init Script
RUN sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
# Make GitLab start on boot
RUN sudo update-rc.d gitlab defaults 21
# Install Gitaly
# Fetch Gitaly source with Git and compile with Go
RUN sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly]" RAILS_ENV=production
# Restrict Gitaly socket access
RUN sudo chmod 0700 /home/git/gitlab/tmp/sockets/private && sudo chown git /home/git/gitlab/tmp/sockets/private
# Setup Logrotate
RUN sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
# Compile GetText PO files
RUN sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production
# Compile Assets
RUN sudo -u git -H yarn install --production --pure-lockfile && sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production
# Start GitLab Instance
RUN sudo service gitlab start
# install nginx
RUN sudo apt-get install -y nginx
# Site Configuration
RUN sudo cp lib/support/nginx/gitlab /etc/nginx/sites-available/gitlab && sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
# Validate your gitlab or gitlab-ssl Nginx config file
RUN sudo nginx -t
RUN sudo service nginx restart
ENTRYPOINT service postgresql start && sleep 3 && service redis-server start && service gitlab stop && service gitlab start && service nginx start && service ssh start && /bin/bash
