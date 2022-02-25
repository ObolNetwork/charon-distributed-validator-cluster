#!/bin/sh
/usr/local/bin/charon run  --data-dir="./" \
 --manifest-file="../manifest.json" \
 --monitoring-address="127.0.0.1:15015" \
 --validator-api-address="127.0.0.1:15016" \
 --p2p-tcp-address=127.0.0.1:15013 \
 --p2p-udp-address=127.0.0.1:15014 \
