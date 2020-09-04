# config valid for current version and patch releases of Capistrano
lock "~> 3.14.1"

set :application, "firstApp"
set :repo_url, "git@example.com:me/firstApp.git"

set :user,            'deploy'
set :puma_threads,    [4, 16]
set :puma_workers,    0

set :pty,             true
set :use_sudo,        true
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
# set :sidekiq_monit_use_sudo, false

# Default value for :linked_files is []
set :linked_files, %w{
  config/database.yml
  config/application.yml
  config/secrets.yml
  config/master.key
  config/nginx.conf
  .env
}


# Default value for linked_dirs is []
set :linked_dirs, %w{
  log
  tmp/pids
  tmp/cache
  tmp/sockets
  public/system
}

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

    before :start, :make_dirs
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse anx/master`
        puts "WARNING: HEAD is not the same as anx/master"
        puts "Run `git push` to sync changes."
      exit
    end
  end
end

desc 'Initial Deploy'
  task :initial do
  on roles(:app) do
    before 'deploy:restart', 'puma:start'
    invoke 'deploy'
  end
end

desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
    invoke 'puma:restart'
  end
end

desc 'Upload to shared/config'
  task :upload do
  on roles (:app) do
    upload! "config/nginx.conf",  "#{shared_path}/config/nginx.conf"
    upload! "config/master.key",  "#{shared_path}/config/master.key"
    # upload! "config/database.yml", "#{shared_path}/config/application.yml"  #-> option
    # 把 database.yml 推上去 shared 目錄 （remember to link_file)
    upload! "config/database.yml", "#{shared_path}/config/database.yml"  #-> option
    # upload! "config/secrets.yml",  "#{shared_path}/config/secrets.yml"   #-> option
    # upload! ".env",  "#{shared_path}/.env"                               #-> option
  end
end

before :starting,  :check_revision
after  :finishing, :compile_assets
after  :finishing, :cleanup
after  :finishing, :restart
end

desc "Run rake db:seed on a remote server."
task :seed do
  on roles (:app) do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, "db:seed"
      end
    end
  end
end

namespace :logs do
  desc "tail rails logs"
  task :rails do
    on roles(:app) do
      execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log"
    end
  end
  # desc "tail sidekiq logs"
  # task :sidekiq do
  #   on roles(:app) do
  #     execute "tail -f #{shared_path}/log/sidekiq.log"
  #   end
  # end
end
# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
