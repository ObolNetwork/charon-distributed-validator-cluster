#!/usr/bin/env bash

while ! curl "http://${NODE}:3600/eth/v1/node/health" 2>/dev/null; do
  echo "Waiting for http://${NODE}:3600 to become available..."
  sleep 5
done

for f in /opt/charon/keys/keystore-*.json; do
  echo "Importing key ${f}"
  lighthouse --network "${ETH2_NETWORK}" account validator import \
    --reuse-password \
    --keystore "${f}" \
    --password-file "$(echo "${f}" | sed 's/json/txt/')"
done

echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse --network "${ETH2_NETWORK}" validator \
  --beacon-nodes "http://${NODE}:3600" \
  --suggested-fee-recipient "0x0000000000000000000000000000000000000000" \
  --metrics \
  --metrics-address "0.0.0.0" \
  --metrics-allow-origin "*" \
  --metrics-port "5064" \
  --use-long-timeouts \
