require 'bundler/capistrano'

set :application, "Wit"
set :repository, "https://github.com/omo/wit.git"
set :scm, :git

# FIXME: should use a pretty domain name
role :web, "wit.flakiness.es"
role :app, "wit.flakiness.es"

# http://stackoverflow.com/questions/7747759/how-do-i-set-the-shell-to-bash-for-run-in-capistrano
default_run_options[:shell] = '/bin/bash --login'

# https://help.github.com/articles/deploying-with-capistrano
set :ssh_options, { :forward_agent => true }
set :branch, "master"
set :deploy_via, :remote_cache
set :use_sudo, false
set :bundle_cmd, "bundle"
set :user, "ubuntu"
set :deploy_to, "/home/ubuntu/work/wit"

