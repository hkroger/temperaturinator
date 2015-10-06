#!/bin/bash --login
PATH=$PATH:$HOME/.rvm/bin
source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
rvm use ruby-2.1
cd `dirname $0`
RAILS_ENV=production rails runner Alarm.watch
