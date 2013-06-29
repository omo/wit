set :application, "set your application name here"
set :repository, "https://github.com/omo/wit.git"
set :scm, :git

# FIXME: should use a pretty domain name
role :web, "ec2-50-19-127-155.compute-1.amazonaws.com"
role :app, "ec2-50-19-127-155.compute-1.amazonaws.com"

# https://help.github.com/articles/deploying-with-capistrano
set :ssh_options, { :forward_agent => true }
set :branch, "master"
set :deploy_via, :remote_cache
set :use_sudo, false

set :user, "ubuntu"
set :deploy_to, "/home/ubuntu/work/wit"
set :scm_username, "omo"
