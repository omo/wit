load 'deploy'
load 'config/deploy' # remove this line to skip loading any of the default tasks

after "deploy:update" do
  # XXX: nginx, upstart
  # run "#{sudo} ln -nsf /path/to/real/config.yml /u/apps/social/current/config/database.yml"
  run "#{sudo} cp #{current_path}/config/wit-puma.conf /etc/init/wit-puma.conf"
  run "#{sudo} cp #{current_path}/config/wit-puma.conf /etc/nginx/sites-enabled/wit.conf"
end

after "deploy:restart" do
  run "#{sudo} stop wit-puma"
  run "#{sudo} start wit-puma"
  run "#{sudo} stop nginx"
  run "#{sudo} start nginx"
end
