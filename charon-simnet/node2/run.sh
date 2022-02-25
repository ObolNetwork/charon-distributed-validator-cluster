#!/bin/sh
/usr/local/bin/charon run  --data-dir="./" \
 --manifest-file="../manifest.json" \
 --monitoring-address="127.0.0.1:15011" \
 --validator-api-address="127.0.0.1:15012" \
 --p2p-tcp-address=127.0.0.1:15009 \
 --p2p-udp-address=127.0.0.1:15010 \
