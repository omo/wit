load 'deploy'
load 'config/deploy' # remove this line to skip loading any of the default tasks

after "deploy:update" do
  run "#{sudo} cp #{current_path}/config/wit-puma.conf /etc/init/wit-puma.conf"
  run "#{sudo} cp #{current_path}/config/wit-nginx.conf /etc/nginx/sites-enabled/010wit.conf"
end

after "deploy:restart" do
  run "#{sudo} restart wit-puma"
  run "#{sudo} /etc/init.d/nginx start"
end

