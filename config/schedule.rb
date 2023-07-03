job_type :rake, "export PATH=\"$HOME/.rbenv/bin:$PATH\"; eval \"$(rbenv init -)\"; cd :path && RAILS_ENV=:environment bundle exec rake :task :output"
set :output, 'log/cron.log'
set :environment, :production

every 1.minute do
  rake 'schedule_remind:remind'
end