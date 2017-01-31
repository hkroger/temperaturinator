LOGFILE=/var/www/measurinator/current/log/production.log

multitail -l "ssh node2 \"tail -f $LOGFILE\"" -l "ssh node3 \"tail -f $LOGFILE\"" -l "ssh node4 \"tail -f $LOGFILE\""
