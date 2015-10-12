#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin/:/usr/lib/dart/bin
export HOME=/root
DIRROOT=/dartdoc-generator

case $1 in
   start)
      echo $$ > /var/run/package_generator.pid;
      mkdir -p $DIRROOT/logs
      exec 2>&1 dart $DIRROOT/bin/package_generator.dart --dirroot $DIRROOT 1>$DIRROOT/logs/log.txt
      ;;
    stop)
      kill `cat /var/run/package_generator.pid` ;;
    *)
      echo "usage: monit.sh {start|stop}" ;;
esac
exit 0