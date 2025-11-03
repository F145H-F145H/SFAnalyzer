#!/bin/sh
case "$1" in
start)
	echo "Finally, free pagecache, dentries and inodes ..."
	# Tune kernel min free memory
	#echo 8192 > /proc/sys/vm/min_free_kbytes
	echo 200 > /proc/sys/vm/vfs_cache_pressure
	# Clean cache after boot finish
	echo 3 > /proc/sys/vm/drop_caches
	;;
stop)
	;;
esac
