#!/bin/sh
echo [$0] > /dev/console
if [ "`rgdb -i -g /runtime/nvram/bgonly`" = "1" ]; then
	rgdb -s /wireless/wlanmode 3
else
	rgdb -s /wireless/wlanmode 7
fi

