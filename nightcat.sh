#!/bin/sh

logger -i "nightcat checking"

MYPID=$$
ALREADY_RUNNING=""

ps ax | fgrep nightcat | grep -v grep | awk '{ print $1 }' > /tmp/nightcat.tmp

for file in `cat /tmp/nightcat.tmp` ; do
    if [ "$MYPID" != "$file"  ] ; then
	##echo ALREADY_RUNNING="true"
	ALREADY_RUNNING="true"
    fi
done

if [ "${ALREADY_RUNNING}" = "true" ] ; then
    logger -i "nightcat already running, exit"
    ##echo "nightcat already running, exit"
    exit;
fi

logger -i "nightcat real start"

echo ${MYPID} > /var/tmp/dpride/nightcat.pid

while [ 1 ] ; do
    echo 'nightcat now!' > /tmp/nightcat.test
    ##echo 'nightcat now!'
    sleep 120
done

logger -i "nightcat real stop"
