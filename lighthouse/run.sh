#!/usr/bin/env bash

apt-get update && apt-get install -y curl jq wget

while ! curl "${LIGHTHOUSE_BEACON_NODE_ADDRESS}/eth/v1/node/health" 2>/dev/null; do
  echo "Waiting for ${LIGHTHOUSE_BEACON_NODE_ADDRESS} to become available..."
  sleep 5
done

# Refer: https://lighthouse-book.sigmaprime.io/advanced-datadir.html
# Running a lighthouse VC involves two steps which needs to run in order:
# 1. Loading the validator keys
# 2. Actually running the VC

# Remove previously imported keys, but keep the slashing protection DB
# (validators/slashing_protection.sqlite) across restarts.
VALIDATORS_DIR="/root/.lighthouse/${ETH2_NETWORK}/validators"
rm -rf "${VALIDATORS_DIR}"/0x* "${VALIDATORS_DIR}/validator_definitions.yml"

for f in /opt/charon/keys/keystore-*.json; do
  echo "Importing key ${f}"
  lighthouse --network "${ETH2_NETWORK}" account validator import \
    --reuse-password \
    --keystore "${f}" \
    --password-file "${f//json/txt}"
done

BUILDER_ARGS=""
if [ "${BUILDER_API_ENABLED}" = "true" ]; then
  BUILDER_ARGS="--builder-proposals"
fi

echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse --network "${ETH2_NETWORK}" validator \
  --beacon-nodes ${LIGHTHOUSE_BEACON_NODE_ADDRESS} \
  --suggested-fee-recipient "${FEE_RECIPIENT}" \
  --metrics \
  --metrics-address "0.0.0.0" \
  --metrics-allow-origin "*" \
  --metrics-port "5064" \
  --use-long-timeouts \
  ${BUILDER_ARGS} \
  --distributed
