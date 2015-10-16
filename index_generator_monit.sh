#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin/:/usr/lib/dart/bin
export HOME=/root
DIRROOT=/dartdoc-generator

case $1 in
   start)
      echo $$ > /var/run/index_generator.pid;
      mkdir -p $DIRROOT/logs
      exec 2>&1 dart $DIRROOT/bin/index_generator.dart --dirroot $DIRROOT 1>>$DIRROOT/logs/index_generator_log.txt
      ;;
    stop)
      kill `cat /var/run/index_generator.pid` ;;
    *)
      echo "usage: monit.sh {start|stop}" ;;
esac
exit 0