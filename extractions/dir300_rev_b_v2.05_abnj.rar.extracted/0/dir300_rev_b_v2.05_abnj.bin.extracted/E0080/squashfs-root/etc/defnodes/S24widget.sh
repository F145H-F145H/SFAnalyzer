#!/bin/sh
#To set the system info into runtime according to SPEC v1.11
xmldbc -x /runtime/sys/info/fwmajor				"get:cut -d. -f1 /etc/config/buildver"
xmldbc -x /runtime/sys/info/fwminor				"get:cut -d. -f2 /etc/config/buildver"
xmldbc -x /runtime/sys/info/fwyear				"get:scut -f4 /etc/config/builddate"
xmldbc -x /runtime/sys/info/fwmonth				"get:scut -f3 /etc/config/builddate"
xmldbc -x /runtime/sys/info/fwday				"get:scut -f2 /etc/config/builddate"
xmldbc -x /runtime/sys/info/langs				"get:cat /etc/config/langs"
