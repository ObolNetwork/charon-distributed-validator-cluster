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

# Now run prysm VC
exec /app/cmd/validator/validator \
    --wallet-dir="${WALLET_DIR}" \
    --wallet-password-file="${WALLET_PASSWORD_FILE}" \
    --accept-terms-of-use=true \
    --datadir="/data/vc" \
    --enable-beacon-rest-api \
    --beacon-rest-api-provider="${BEACON_NODE_ADDRESS}" \
    --beacon-rpc-provider="${BEACON_NODE_ADDRESS}" \
    --suggested-fee-recipient="${FEE_RECIPIENT}" \
    --monitoring-host=0.0.0.0 \
    --monitoring-port=8081 \
    --"${NETWORK}" \
    ${BUILDER_ARGS} \
    --distributed
