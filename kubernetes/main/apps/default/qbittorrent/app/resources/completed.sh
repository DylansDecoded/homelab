#!/bin/bash
# qBittorrent settings > 'Run external program on torrent finished'
# /scripts/completed.sh "%F"
/usr/bin/curl --silent --request POST --data-urlencode "path=$1" http://cross-seed.default.svc.cluster.local/api/webhook
