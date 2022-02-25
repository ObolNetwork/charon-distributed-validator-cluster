#!/bin/sh
/usr/local/bin/charon run  --data-dir="/tmp/charon-simnet/node0" \
 --manifest-file="/tmp/charon-simnet/manifest.json" \
 --monitoring-address="127.0.0.1:15003" \
 --validator-api-address="127.0.0.1:15004" \
 --p2p-tcp-address=127.0.0.1:15001 \
 --p2p-udp-address=127.0.0.1:15002 \
