#!/bin/sh
image_sign=`cat /etc/config/image_sign`

case "$1" in
start)
	echo "Mounting proc and var ..."
	mount -t proc none /proc
	mount -t sysfs sysfs /sys
	mount -t ramfs ramfs /var
	mkdir -p /var/etc /var/log /var/run /var/state /var/tmp /var/etc/ppp /var/etc/config /var/dnrd /var/etc/iproute2
	echo -n > /var/etc/resolv.conf
	echo -n > /var/TZ
	echo "127.0.0.1 hgw" > /var/hosts

	# Tune ip_conntrack hash table size, hash table size = max session * 2 is recommended.
	echo 8192 > /sys/module/ip_conntrack/parameters/hashsize

	# Tune route cache flush timeout
	echo 4096 > /proc/sys/net/ipv4/route/gc_thresh
	echo 8192 > /proc/sys/net/ipv4/route/max_size
	echo 30 > /proc/sys/net/ipv4/route/secret_interval

	# if no PIN, generate one
	#pin=`devdata get -e pin`
	#[ "$pin" = "" ] && devdata set -e pin=`wps -g`

	# prepare db...
	echo "Start xmldb ..." > /dev/console
	xmldb -n $image_sign -t > /dev/console &
	sleep 1
	/etc/scripts/misc/profile.sh get
	/etc/templates/timezone.sh set
	/etc/templates/logs.sh
	sleep 1
	logger -p 192.1 "SYS:001"

	# bring up network devices
	ifconfig lo up

	PANIC=`rgdb -i -g /runtime/func/panic_reboot`
	[ "$PANIC" != "" ] && echo "$PANIC" > /proc/sys/kernel/panic

	TIMEOUT=`rgdb -g /nat/general/tcpidletimeout`
	[ "$TIMEOUT" = "" ] && TIMEOUT=7200 && rgdb -s /nat/general/tcpidletimeout $TIMEOUT
	echo "$TIMEOUT" > /proc/sys/net/ipv4/netfilter/ip_conntrack_tcp_timeout_established

	# Setup bridge
	brctl addbr br0 	> /dev/console
	brctl stp br0 off	> /dev/console
	brctl setfd br0 0	> /dev/console
	# Start up LAN interface & httpd
	ifconfig br0 0.0.0.0 up			> /dev/console
	/etc/templates/webs.sh start	> /dev/console
	;;
stop)
	umount /tmp
	umount /proc
	umount /var
	;;
esac
