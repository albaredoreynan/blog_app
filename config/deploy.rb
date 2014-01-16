require "bundler/capistrano"
 
 
set :application, "blog_app"
set :user, "azureuser"
 
 
set :scm, :git
set :repository, "git@github.com:albaredoreynan/blog_app.git"
set :branch, "master"
set :use_sudo, true
 
 
server "restobot-test.cloudapp.net", :web, :app, :db, primary: true
 
set :deploy_to, "/home/#{user}/apps/#{application}"
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:port] = 22


namespace :devtasks do
  desc "taks for developers"
  task :restart_app do
    run "service unicorn_restobotv3 stop"
    sudo "service nginx stop"
    sudo "service nginx start"
    run "service unicorn_restobotv3 start"
    # cap devtasks:restart_app
  end
end 
 
namespace :deploy do
  desc "Fix permissions"
  task :fix_permissions, :roles => [ :app, :db, :web ] do
    run "chmod +x #{release_path}/config/unicorn_init.sh"
  end
 
 
  %w[start stop restart].each do |command|
    desc "#{command} unicorn server"
    task command, roles: :app, except: {no_release: true} do
      run "service unicorn_#{application} #{command}"
    end
  end
 
 
  task :setup_config, roles: :app do
    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
    sudo "mkdir -p #{shared_path}/config"
  end
  after "deploy:setup", "deploy:setup_config"
 
 
  task :symlink_config, roles: :app do
    # Add database config here
  end
  
  after "deploy:finalize_update", "deploy:fix_permissions"
  after "deploy:finalize_update", "deploy:symlink_config"

  task :restart_unicorn, roles: :app do
    run "service unicorn_restobotv3 restart"
  end

  after "deploy:finalize_update", "deploy:restart_unicorn"

end
