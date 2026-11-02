#!/bin/sh
# One-line world clock for hyprlock: "London 12:05  ·  New York 07:05  ·  Manila 20:05 +1"
# First zone is Lusaka<->London, whichever one isn't the local zone.
here=$(timedatectl show -p Timezone --value)
if [ "$here" = Europe/London ]; then first=Africa/Lusaka; else first=Europe/London; fi

today=$(date +%Y%m%d)
out=
for tz in "$first" America/New_York Asia/Manila; do
    day=$(TZ=$tz date +%Y%m%d)
    mark=
    [ "$day" -gt "$today" ] && mark=' +1'
    [ "$day" -lt "$today" ] && mark=' -1'
    name=$(echo "${tz##*/}" | tr _ ' ')
    out="${out:+$out  ·  }$name $(TZ=$tz date +%H:%M)$mark"
done
echo "$out"
