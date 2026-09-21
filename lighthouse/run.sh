#!/usr/bin/env bash

# Lighthouse validator client entrypoint for the Platåberget devnet.
# The network is a custom devnet, so both the key import and the validator
# client are pointed at the mounted testnet-dir instead of a named --network.
# The beacon "node" is the local charon node (node<N>:3600).

# Refer: https://lighthouse-book.sigmaprime.io/advanced-datadir.html
# Running a lighthouse VC involves two steps which need to run in order:
# 1. Import the validator keys
# 2. Run the VC

for f in /opt/charon/keys/keystore-*.json; do
  echo "Importing key ${f}"
  lighthouse --testnet-dir /network-config account validator import \
    --reuse-password \
    --keystore "${f}" \
    --password-file "${f//json/txt}"
done

echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse --testnet-dir /network-config validator \
  --beacon-nodes "${LIGHTHOUSE_BEACON_NODE_ADDRESS}" \
  --suggested-fee-recipient "0x0000000000000000000000000000000000000000" \
  --metrics \
  --metrics-address "0.0.0.0" \
  --metrics-allow-origin "*" \
  --metrics-port "5064" \
  --use-long-timeouts \
  --distributed
