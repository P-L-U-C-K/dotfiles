#!/bin/sh
for i in 1 2 3 4 5 6 7 8; do
    wlr-randr --output DP-2 --on --mode 1920x1080@60 --pos 0,0 \
              --output HDMI-A-1 --on --mode 1920x1080@119.982 --pos 0,1080
    sleep 1
    wlr-randr | grep -A8 '^HDMI-A-1' | grep -q 'Position: 0,1080' && break
done
