#!/bin/bash

# Lighthouse validator client entrypoint for the Platåberget devnet.
# Authors validator_definitions.yml from the mounted charon keystores (replacing
# `lighthouse account validator import`) and applies per-validator proposer
# settings from the charon-generated proposer-config.json when present. The
# network is a custom devnet, so --testnet-dir is used instead of --network.

KEYS_DIR="/opt/charon/validator_keys"
PROPOSER_CONFIG="/opt/charon/vc-config/proposer-config.json"
VALIDATORS_DIR="/opt/data/validators"
DEFINITIONS="${VALIDATORS_DIR}/validator_definitions.yml"

mkdir -p "${VALIDATORS_DIR}"

if [[ -f "${PROPOSER_CONFIG}" ]]; then
    echo "proposer-config.json found, applying proposer settings per validator"
else
    echo "proposer-config.json not found, generating validator definitions without proposer settings"
fi

# Regenerated on every start so proposer-config.json updates apply on restart.
rm -f "${DEFINITIONS}.tmp"
for keystore in "${KEYS_DIR}"/keystore-*.json; do
    pubkey="0x$(jq -r .pubkey "${keystore}")"

    {
        echo "- enabled: true"
        echo "  voting_public_key: \"${pubkey}\""
        echo "  type: local_keystore"
        echo "  voting_keystore_path: ${keystore}"
        echo "  voting_keystore_password_path: ${keystore%.json}.txt"

        if [[ -f "${PROPOSER_CONFIG}" ]]; then
            # Entries only carry fields diverging from default_config; absent fields fall back to it.
            fee_recipient=$(jq -r --arg pk "${pubkey}" '.proposer_config[$pk].fee_recipient // .default_config.fee_recipient' "${PROPOSER_CONFIG}")
            gas_limit=$(jq -r --arg pk "${pubkey}" '.proposer_config[$pk].gas_limit // .default_config.gas_limit' "${PROPOSER_CONFIG}")

            echo "  suggested_fee_recipient: \"${fee_recipient}\""
            echo "  gas_limit: ${gas_limit}"
            echo "  builder_proposals: ${BUILDER_API_ENABLED}"
        fi
    } >>"${DEFINITIONS}.tmp"
done
mv "${DEFINITIONS}.tmp" "${DEFINITIONS}"

echo "Generated ${DEFINITIONS}"

EXTRA_FLAGS=()
if [[ ! -f "${PROPOSER_CONFIG}" ]]; then
    # Global fallbacks when validator definitions carry no proposer settings.
    EXTRA_FLAGS+=(--suggested-fee-recipient "0x0000000000000000000000000000000000000000")

    if [[ "${BUILDER_API_ENABLED}" == "true" ]]; then
        EXTRA_FLAGS+=(--builder-proposals)
    fi
fi

exec lighthouse validator_client \
    --testnet-dir /network-config \
    --datadir /opt/data \
    --beacon-nodes "${BEACON_NODE_ADDRESS}" \
    --distributed \
    --disable-auto-discover \
    --init-slashing-protection \
    --metrics \
    --metrics-address 0.0.0.0 \
    --metrics-port 5064 \
    "${EXTRA_FLAGS[@]}"
