#!/bin/sh

# Nimbus validator client entrypoint for the Platåberget devnet.
# Imports the charon keystores once (via the beacon-node deposits tool bundled
# into this image), applies per-validator proposer settings from the
# charon-generated proposer-config.json, then runs the validator client. The
# network spec is derived from the beacon node (charon).
set -e

BN=/home/user/nimbus_beacon_node
VC=$(command -v nimbus_validator_client || echo /home/user/nimbus_validator_client)
DATA=/home/user/data

# Import keys once; nimbus persists them in DATA/validators, so skip on restart.
if [ -z "$(ls -A "${DATA}/validators" 2>/dev/null)" ]; then
  echo "importing keys (first run)"
  tmpkeys=/home/validator_keys/tmpkeys
  mkdir -p "${tmpkeys}"
  for f in /home/validator_keys/keystore-*.json; do
    cp "${f}" "${tmpkeys}"
    cat "${f%.json}.txt" | "${BN}" deposits import --data-dir="${DATA}" "${tmpkeys}" >/dev/null 2>&1
    rm "${tmpkeys}/${f##*/}"
  done
  rm -r "${tmpkeys}"
  echo "imported all keys"
else
  echo "keys already imported, skipping"
fi

# Apply per-validator proposer settings (re-applied each start so updates take effect).
CONFIG=/home/charon/vc-config/proposer-config.json
if [ -f "${CONFIG}" ]; then
  echo "proposer-config.json found, rendering per-validator proposer settings"
  for f in /home/validator_keys/keystore-*.json; do
    pubkey="0x$(jq -r .pubkey "${f}")"
    fee_recipient=$(jq -r --arg pk "${pubkey}" '.proposer_config[$pk].fee_recipient // .default_config.fee_recipient' "${CONFIG}")
    gas_limit=$(jq -r --arg pk "${pubkey}" '.proposer_config[$pk].gas_limit // .default_config.gas_limit' "${CONFIG}")

    for dir in "${DATA}/validators/${pubkey}" "${DATA}/validators/${pubkey#0x}"; do
      if [ -d "${dir}" ]; then
        echo "${fee_recipient}" >"${dir}/suggested_fee_recipient.hex"
        echo "${gas_limit}" >"${dir}/suggested_gas_limit.json"
      fi
    done
  done
else
  echo "proposer-config.json not found, running without proposer settings"
fi

exec "${VC}" \
  --data-dir="${DATA}" \
  --beacon-node="${BEACON_NODE_ADDRESS}" \
  --doppelganger-detection=false \
  --metrics \
  --metrics-address=0.0.0.0 \
  --payload-builder="${BUILDER_API_ENABLED}" \
  --distributed
