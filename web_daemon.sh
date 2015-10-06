#!/bin/bash --login
PATH=$PATH:$HOME/.rvm/bin
source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
rvm use 2.1
cd `dirname $0`
RAILS_RELATIVE_URL_ROOT=/thermometer
RAILS_ENV=production bundle exec rake assets:precompile &
RAILS_ENV=production unicorn -p 4000
