#!/usr/bin/env bash

apt-get update && apt-get install -y curl jq wget

while ! curl "${LIGHTHOUSE_BEACON_NODE_ADDRESS}/eth/v1/node/health" 2>/dev/null; do
  echo "Waiting for ${LIGHTHOUSE_BEACON_NODE_ADDRESS} to become available..."
  sleep 5
done

# On a fresh setup charon writes proposer-config.json shortly after it starts, wait for it.
PROPOSER_CONFIG="/opt/charon/node/vc-config/proposer-config.json"
for _ in $(seq 60); do
  [ -f "${PROPOSER_CONFIG}" ] && break
  sleep 2
done

# Refer: https://lighthouse-book.sigmaprime.io/advanced-datadir.html
# Author validator_definitions.yml from the mounted charon keystores instead of
# `lighthouse account validator import`, so the per-validator proposer settings
# from proposer-config.json apply on every start.

# Remove previously imported keys, but keep the slashing protection DB
# (validators/slashing_protection.sqlite) across restarts.
VALIDATORS_DIR="/root/.lighthouse/${ETH2_NETWORK}/validators"
DEFINITIONS="${VALIDATORS_DIR}/validator_definitions.yml"
rm -rf "${VALIDATORS_DIR}"/0x* "${DEFINITIONS}"
mkdir -p "${VALIDATORS_DIR}"

if [ -f "${PROPOSER_CONFIG}" ]; then
  echo "proposer-config.json found, applying proposer settings per validator"
else
  echo "proposer-config.json not found, using FEE_RECIPIENT for all validators"
fi

for keystore in /opt/charon/keys/keystore-*.json; do
  pubkey="0x$(jq -r .pubkey "${keystore}")"

  {
    echo "- enabled: true"
    echo "  voting_public_key: \"${pubkey}\""
    echo "  type: local_keystore"
    echo "  voting_keystore_path: ${keystore}"
    echo "  voting_keystore_password_path: ${keystore%.json}.txt"

    if [ -f "${PROPOSER_CONFIG}" ]; then
      # Entries only carry fields diverging from default_config, absent fields fall back to it.
      fee_recipient=$(jq -r --arg pk "${pubkey}" '.proposer_config[$pk].fee_recipient // .default_config.fee_recipient' "${PROPOSER_CONFIG}")
      gas_limit=$(jq -r --arg pk "${pubkey}" '.proposer_config[$pk].gas_limit // .default_config.gas_limit' "${PROPOSER_CONFIG}")

      echo "  suggested_fee_recipient: \"${fee_recipient}\""
      echo "  gas_limit: ${gas_limit}"
      echo "  builder_proposals: ${BUILDER_API_ENABLED}"
    fi
  } >>"${DEFINITIONS}"
done

echo "Generated ${DEFINITIONS}"

BUILDER_ARGS=""
if [ "${BUILDER_API_ENABLED}" = "true" ]; then
  BUILDER_ARGS="--builder-proposals"
fi

echo "Starting lighthouse validator client"
exec lighthouse --network "${ETH2_NETWORK}" validator \
  --beacon-nodes ${LIGHTHOUSE_BEACON_NODE_ADDRESS} \
  --suggested-fee-recipient "${FEE_RECIPIENT}" \
  --init-slashing-protection \
  --disable-auto-discover \
  --metrics \
  --metrics-address "0.0.0.0" \
  --metrics-allow-origin "*" \
  --metrics-port "5064" \
  --use-long-timeouts \
  ${BUILDER_ARGS} \
  --distributed
