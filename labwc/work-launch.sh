#!/bin/sh
# ~/.config/labwc/work-launch.sh
# Launches the work apps. In parallel, an "arranger" watches the window list with
# lswt and, as soon as new windows appear, opens tiny short-lived helper windows
# (app ids work-arrange / work-arrange-firefox / work-finish). Window rules in
# rc.xml fire on those and move the work windows to their desktop and monitor.
#
# Needs lswt. Log: /tmp/work-launch.log

LOG=/tmp/work-launch.log
log() { echo "$(date +%T) $*" >>"$LOG"; }
: >"$LOG"

HAVE_LSWT=0
command -v lswt >/dev/null 2>&1 && HAVE_LSWT=1

# Window list without our own helper windows (they would retrigger the arranger).
list_windows() {
    lswt 2>/dev/null | grep -viE 'work-(arrange|finish)'
}

count_windows() {
    list_windows | wc -l
}

# Open a tiny helper window; its rule in rc.xml does the work. It exits by itself.
fire() {
    foot -W 1x1 -a "$1" sleep 1 >/dev/null 2>&1 &
}

windows_up() {
    out=$(list_windows) || return 1
    for pat in libreoffice-calc lkahaieplk ompifgpmdd faolnafnng hjckjhgadd; do
        echo "$out" | grep -qi "$pat" || return 1
    done
}

titles_up() {
    out=$(list_windows) || return 1
    echo "$out" | grep -qiE 'subway|servicenow' || return 1
    echo "$out" | grep -qi 'canopy'
}

# Runs alongside the launches. Re-arranges ~0.5s after any new window appears,
# re-arranges Firefox whenever a Firefox page title shows up, then does one
# final safety pass and switches to desktop 2.
arranger() {
    seen=$(count_windows)
    sig=0
    pending=0
    settled=0
    i=0
    while [ "$i" -lt 40 ]; do                      # ~60s max
        n=$(count_windows)
        [ "$n" -gt "$seen" ] && pending=2
        seen=$n

        if [ "$pending" -gt 0 ]; then
            pending=$((pending - 1))
            if [ "$pending" -eq 0 ]; then
                log "arrange apps ($n windows)"
                fire work-arrange
            fi
        fi

        s=$(list_windows | grep -ciE 'subway|servicenow|canopy')
        if [ "$s" != "$sig" ]; then
            sig=$s
            if [ "$s" -gt 0 ]; then
                log "arrange firefox ($s titles)"
                fire work-arrange-firefox
            fi
        fi

        if windows_up && titles_up; then
            settled=$((settled + 1))
        else
            settled=0
        fi
        [ "$settled" -ge 8 ] && break               # all up and quiet for ~2s

        sleep 0.25
        i=$((i + 1))
    done

    #log "final pass"
    #fire work-arrange
    #sleep 0.4
    #fire work-arrange-firefox
    #sleep 1.5
    #fire work-finish
    #log "done"
}

# launch_wait waits for the window of the FIRST launch of a browser family, so
# later launches join the running instance instead of racing it.
launch() {
    "$@" >/dev/null 2>&1 &
}

launch_wait() {
    before=$(count_windows)
    "$@" >/dev/null 2>&1 &
    if [ "$HAVE_LSWT" -eq 0 ]; then
        sleep 4
        return
    fi
    i=0
    while [ "$i" -lt 80 ]; do
        [ "$(count_windows)" -gt "$before" ] && { sleep 0.2; return; }
        sleep 0.25
        i=$((i + 1))
    done
}

if [ "$HAVE_LSWT" -eq 1 ]; then
    arranger &
    ARRANGER=$!
fi

CHROMIUM="flatpak run org.chromium.Chromium --profile-directory=Default"

launch      flatpak run org.libreoffice.LibreOffice --calc
launch_wait $CHROMIUM --app-id=lkahaieplkadlbenndabamkfdenihfbh
launch      $CHROMIUM --app-id=ompifgpmddkgmclendfeacglnodjjndh
launch      $CHROMIUM --app-id=faolnafnngnfdaknnbpnkhgohbobgegn
launch      $CHROMIUM --app-id=hjckjhgaddkfkplbkngnjipjookbmiad
launch_wait firefox --new-window https://subway.service-now.com/
launch      firefox --new-window https://portal.my-canopy.com/
log "all launched"

if [ "$HAVE_LSWT" -eq 1 ]; then
    wait "$ARRANGER"
else
    :   # no-op: fallback below is disabled
#    # No lswt: fixed timing fallback.
#    sleep 10
#    fire work-arrange
#    sleep 1
#    fire work-arrange-firefox
#    sleep 1.5
#     fire work-finish
fi

