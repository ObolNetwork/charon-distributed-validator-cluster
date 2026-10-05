#!/usr/bin/env bash

WALLET_DIR="/prysm-wallet"
WALLET_PASSWORD_FILE="/wallet-password.txt"

# Cleanup wallet directories if already exists.
# The slashing protection DB lives in --datadir (/data/vc) and is kept across restarts.
rm -rf "${WALLET_DIR}"
mkdir "${WALLET_DIR}"

# Refer: https://prysm.offchainlabs.com/docs/install-prysm/install-with-script/#step-5-run-a-validator-using-prysm
# Running a prysm VC involves two steps which need to run in order:
# 1. Import validator keys in a prysm wallet account.
# 2. Run the validator client.
echo "prysm-validator-secret" > "${WALLET_PASSWORD_FILE}"
/app/cmd/validator/validator wallet create \
    --accept-terms-of-use \
    --wallet-password-file="${WALLET_PASSWORD_FILE}" \
    --keymanager-kind=direct \
    --wallet-dir="${WALLET_DIR}"

tmpkeys="/home/validator_keys/tmpkeys"
mkdir -p "${tmpkeys}"

for f in /home/charon/validator_keys/keystore-*.json; do
    echo "Importing key ${f}"

    # Copy keystore file to tmpkeys/ directory.
    cp "${f}" "${tmpkeys}"

    # Import keystore with password.
    /app/cmd/validator/validator accounts import \
        --accept-terms-of-use=true \
        --wallet-dir="${WALLET_DIR}" \
        --keys-dir="${tmpkeys}" \
        --account-password-file="${f//json/txt}" \
        --wallet-password-file="${WALLET_PASSWORD_FILE}"

    # Delete tmpkeys/keystore-*.json file that was copied before.
    rm "${tmpkeys}/$(basename "${f}")"
done

# Delete the tmpkeys/ directory since it's no longer needed.
rm -r "${tmpkeys}"

echo "Imported all keys"

BUILDER_ARGS=""
if [ "${BUILDER_API_ENABLED}" = "true" ]; then
    BUILDER_ARGS="--enable-builder"
fi

# On a fresh setup charon writes proposer-config.json shortly after it starts, wait for it.
PROPOSER_CONFIG="/opt/charon/node/vc-config/proposer-config.json"
for _ in $(seq 60); do
    [ -f "${PROPOSER_CONFIG}" ] && break
    sleep 2
done

# Render Prysm's proposer settings from charon's proposer-config.json: entries only carry
# fields diverging from default_config, absent fields fall back to it. Rendered as v2
# settings with a top-level gas_limit, since from gloas Prysm ignores the legacy
# builder.gas_limit. The legacy builder block is kept for pre-gloas builder registrations.
PROPOSER_SETTINGS=(--suggested-fee-recipient="${FEE_RECIPIENT}")
if [ -f "${PROPOSER_CONFIG}" ]; then
    echo "proposer-config.json found, rendering prysm proposer settings"
    jq --argjson enabled "${BUILDER_API_ENABLED}" '
        .default_config as $d |
        {
            version: 2,
            proposer_config: (.proposer_config | map_values({
                fee_recipient: (.fee_recipient // $d.fee_recipient),
                gas_limit: (.gas_limit // $d.gas_limit),
                builder: {enabled: $enabled, gas_limit: (.gas_limit // $d.gas_limit)}
            })),
            default_config: {
                fee_recipient: $d.fee_recipient,
                gas_limit: $d.gas_limit,
                builder: ({enabled: $enabled, gas_limit: $d.gas_limit} + ($d.builder // {}))
            }
        }' "${PROPOSER_CONFIG}" >/tmp/prysm-proposer-settings.json
    PROPOSER_SETTINGS=(--proposer-settings-file=/tmp/prysm-proposer-settings.json)
else
    echo "proposer-config.json not found, using FEE_RECIPIENT for all validators"
fi

# A network the client doesn't know by name, e.g. a devnet, is configured by mounting its
# network config directory (config.yaml, genesis.ssz, ...) at /network-config.
NETWORK_ARGS=(--"${NETWORK}")
if [ -f /network-config/config.yaml ]; then
    NETWORK_ARGS=(--chain-config-file=/network-config/config.yaml)
fi

# Now run prysm VC.
# From the gloas fork, request the stateless (payload-included) block form: charon spreads block
# production across nodes, so no single beacon node can be relied on to hold the payload envelope
# for the stateful form. Prysm only forces it on with more than one beacon node.
exec /app/cmd/validator/validator \
    --wallet-dir="${WALLET_DIR}" \
    --wallet-password-file="${WALLET_PASSWORD_FILE}" \
    --accept-terms-of-use=true \
    --datadir="/data/vc" \
    --enable-beacon-rest-api \
    --beacon-rest-api-provider="${BEACON_NODE_ADDRESS}" \
    --beacon-rpc-provider="${BEACON_NODE_ADDRESS}" \
    --monitoring-host=0.0.0.0 \
    --monitoring-port=8081 \
    "${NETWORK_ARGS[@]}" \
    ${BUILDER_ARGS} \
    --distributed \
    --stateless \
    "${PROPOSER_SETTINGS[@]}"
