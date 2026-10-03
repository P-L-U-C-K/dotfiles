#!/bin/sh
# Emits bluetooth state to yambar: off / on / connected
while true; do
    if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        if bluetoothctl devices Connected 2>/dev/null | grep -q "^Device"; then
            echo "bt|string|connected"
        else
            echo "bt|string|on"
        fi
    else
        echo "bt|string|off"
    fi
    echo ""
    sleep 5
done
