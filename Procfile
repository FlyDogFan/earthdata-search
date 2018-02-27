web: ./start.sh
jobs: bundle exec bin/delayed_job -n 6 run
cron: ./cron.sh
on_build: bundle exec rake deploy:pre
