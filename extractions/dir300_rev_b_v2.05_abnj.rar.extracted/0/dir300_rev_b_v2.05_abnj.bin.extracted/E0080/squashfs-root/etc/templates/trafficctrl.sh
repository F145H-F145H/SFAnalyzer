#!/bin/sh
echo [$0] $1 ... > /dev/console
TROOT="/etc/templates"
[ ! -f $TROOT/extensions/trafficctrl_run.php ] && exit 0
case "$1" in
start|restart)
	[ -f /var/run/trafficctrl_stop.sh ] && sh /var/run/trafficctrl_stop.sh > /dev/console
	xmldbc -A $TROOT/extensions/trafficctrl_run.php -V generate_start=1 > /var/run/trafficctrl_start.sh
	xmldbc -A $TROOT/extensions/trafficctrl_run.php -V generate_start=0 > /var/run/trafficctrl_stop.sh
	sleep 2
	sh /var/run/trafficctrl_start.sh > /dev/console
	;;
stop)
	if [ -f /var/run/trafficctrl_stop.sh ]; then
		sh /var/run/trafficctrl_stop.sh > /dev/console
		rm -f /var/run/trafficctrl_stop.sh
	fi
	;;
*)
	echo "usage: trafficctrl.sh {start|stop|restart}"
	;;
esac
