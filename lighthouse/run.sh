#!/usr/bin/env bash

for f in /opt/charon/keys/keystore-*.json; do
  echo "Importing key ${f}"
  cat "$(echo "${f}" | sed 's/json/txt/')"
  cat "$(echo "${f}" | sed 's/json/txt/')" | lighthouse account validator import \
    --stdin-inputs \
    --directory "/opt/charon/keys"
    --keystore "${f}" 
done


echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse validator \
  --network "${ETH2_NETWORK}" \
  --beacon-nodes "http://${NODE}:16002" \
  --suggested-fee-recipient "0x0000000000000000000000000000000000000000" \
  --metrics \
  --metrics-address "0.0.0.0" \
  --metrics-allow-origin "*" \
  --metrics-port "5064" \
  --use-long-timeouts \
  --graffiti "Distributed Validator - LH"

