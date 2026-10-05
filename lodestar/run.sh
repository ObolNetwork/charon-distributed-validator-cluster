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

# On a fresh setup charon writes proposer-config.json shortly after it starts, wait for it.
PROPOSER_CONFIG="/opt/charon/node/vc-config/proposer-config.json"
for _ in $(seq 60); do
    [ -f "${PROPOSER_CONFIG}" ] && break
    sleep 2
done

# Render Lodestar's proposer settings from charon's proposer-config.json: entries only
# carry fields diverging from default_config, absent fields fall back to it. Lodestar
# only accepts yml/yaml file extensions; JSON is valid YAML. CLI flags override the
# file's default_config, so --suggestedFeeRecipient is only passed without it.
if [ -f "${PROPOSER_CONFIG}" ]; then
    echo "proposer-config.json found, rendering lodestar proposer settings"
    node -e '
        const fs = require("fs");
        const src = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        const d = src.default_config;
        const out = {
            proposer_config: {},
            default_config: {fee_recipient: d.fee_recipient, builder: {gas_limit: d.gas_limit}},
        };
        if (d.builder) {
            Object.assign(out.default_config.builder, {
                min_bid: d.builder.min_bid,
                boost_factor: d.builder.builder_boost_factor,
                max_execution_payment: d.builder.max_execution_payment,
                builders: d.builder.builders,
            });
        }
        for (const [pubkey, entry] of Object.entries(src.proposer_config || {})) {
            out.proposer_config[pubkey] = {
                fee_recipient: entry.fee_recipient ?? d.fee_recipient,
                builder: {gas_limit: entry.gas_limit ?? d.gas_limit},
            };
        }
        fs.writeFileSync(process.argv[2], JSON.stringify(out));
    ' "${PROPOSER_CONFIG}" /tmp/proposer-config.yml
    set -- --proposerSettingsFile=/tmp/proposer-config.yml
    # Lodestar refuses a max execution payment above 0 (trusted payments) without an explicit opt-in.
    if [ "$(node -p 'require(process.argv[1]).default_config.builder?.max_execution_payment ?? "0"' "${PROPOSER_CONFIG}")" != "0" ]; then
        set -- "$@" --allowDangerousTrustedPayments
    fi
else
    echo "proposer-config.json not found, using FEE_RECIPIENT for all validators"
    set -- --suggestedFeeRecipient="${FEE_RECIPIENT}"
fi

# A network the client doesn't know by name, e.g. a devnet, is configured by mounting its
# network config directory (config.yaml, genesis.ssz, ...) at /network-config.
NETWORK_ARG="--network=${NETWORK}"
if [ -f /network-config/config.yaml ]; then
    NETWORK_ARG="--paramsFile=/network-config/config.yaml"
fi

exec node /usr/app/packages/cli/bin/lodestar validator \
    --dataDir="$DATA_DIR" \
    --keystoresDir="$KEYSTORES_DIR" \
    --secretsDir="$SECRETS_DIR" \
    "${NETWORK_ARG}" \
    --beaconNodes="$BEACON_NODE_ADDRESS" \
    --builder="${BUILDER_API_ENABLED}" \
    --builder.selection="${BUILDER_SELECTION}" \
    --metrics=true \
    --metrics.address="0.0.0.0" \
    --metrics.port=5064 \
    --distributed \
    "$@"
