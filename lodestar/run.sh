#!/bin/sh

# Remove the existing keystores to avoid keystore locking issues.
# The slashing protection DB lives in /opt/data/validator-db and is kept across restarts.
rm -rf /opt/data/cache /opt/data/secrets /opt/data/keystores

DATA_DIR="/opt/data"
KEYSTORES_DIR="${DATA_DIR}/keystores"
SECRETS_DIR="${DATA_DIR}/secrets"

mkdir -p "${KEYSTORES_DIR}" "${SECRETS_DIR}"

# Refer: https://chainsafe.github.io/lodestar/run/validator-management/vc-configuration
# Running a lodestar VC involves two steps which need to run in order:
# 1. Loading the validator keys, each with its own password file
# 2. Actually running the VC
for f in /home/charon/validator_keys/keystore-*.json; do
    echo "Importing key ${f}"

    # Extract pubkey from keystore file
    PUBKEY="0x$(grep '"pubkey"' "$f" | awk -F'"' '{print $4}')"
    PUBKEY_DIR="${KEYSTORES_DIR}/${PUBKEY}"
    mkdir -p "${PUBKEY_DIR}"

    # Copy the keystore and its corresponding password file
    install -m 600 "$f" "${PUBKEY_DIR}/voting-keystore.json"
    install -m 600 "${f%.json}.txt" "${SECRETS_DIR}/${PUBKEY}"
done

echo "Imported all keys"

exec node /usr/app/packages/cli/bin/lodestar validator \
    --dataDir="$DATA_DIR" \
    --keystoresDir="$KEYSTORES_DIR" \
    --secretsDir="$SECRETS_DIR" \
    --network="$NETWORK" \
    --beaconNodes="$BEACON_NODE_ADDRESS" \
    --suggestedFeeRecipient="${FEE_RECIPIENT}" \
    --builder="${BUILDER_API_ENABLED}" \
    --builder.selection="${BUILDER_SELECTION}" \
    --metrics=true \
    --metrics.address="0.0.0.0" \
    --metrics.port=5064 \
    --distributed
