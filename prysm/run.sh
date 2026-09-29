#!/usr/bin/env bash

# Prysm validator client entrypoint for the Platåberget devnet.
# Imports the charon keystores into a prysm wallet, renders per-validator
# proposer settings from the charon-generated proposer-config.json, then runs
# the validator client against the local charon node over the beacon REST API.
# The network is a custom devnet, so --chain-config-file is used instead of a
# named --<network> flag.

WALLET_DIR="/prysm-wallet"

# Cleanup wallet directories if already exists.
rm -rf $WALLET_DIR
mkdir $WALLET_DIR

# Running a prysm VC involves two steps which need to run in order:
# 1. Import validator keys in a prysm wallet account.
# 2. Run the validator client.
WALLET_PASSWORD="prysm-validator-secret"
echo $WALLET_PASSWORD > /wallet-password.txt
/app/cmd/validator/validator wallet create --accept-terms-of-use --wallet-password-file=/wallet-password.txt --keymanager-kind=direct --wallet-dir="$WALLET_DIR"

tmpkeys="/home/validator_keys/tmpkeys"
mkdir -p ${tmpkeys}

for f in /home/charon/validator_keys/keystore-*.json; do
    echo "Importing key ${f}"

    # Copy keystore file to tmpkeys/ directory.
    cp "${f}" "${tmpkeys}"

    # Import keystore with password.
    /app/cmd/validator/validator accounts import \
        --accept-terms-of-use=true \
        --wallet-dir="$WALLET_DIR" \
        --keys-dir="${tmpkeys}" \
        --account-password-file="${f//json/txt}" \
        --wallet-password-file=/wallet-password.txt

    # Delete tmpkeys/keystore-*.json file that was copied before.
    filename="$(basename ${f})"
    rm "${tmpkeys}/${filename}"
done

# Delete the tmpkeys/ directory since it's no longer needed.
rm -r ${tmpkeys}

echo "Imported all keys"

# Render Prysm's proposer settings from the charon-generated canonical config when available:
# entries only carry fields diverging from default_config, absent fields fall back to it.
# Emit v2 settings (top-level gas_limit + version:2) gated on gas_limit's presence, not on a
# builder key: charon's proposer-config.json has no builder key, and at the gloas fork prysm
# ignores the legacy builder.gas_limit and falls back to the network default (200M) unless the
# gas limit is set as a top-level v2 field. The builder block is kept for pre-gloas behavior.
PROPOSER_SETTINGS=()
if [[ -f /home/charon/vc-config/proposer-config.json ]]; then
    echo "proposer-config.json found, rendering prysm proposer settings"
    jq --argjson enabled "${BUILDER_API_ENABLED}" '
        .default_config as $d |
        ($d.gas_limit != null) as $g |
        {
            proposer_config: (.proposer_config | map_values(
                {fee_recipient: (.fee_recipient // $d.fee_recipient)}
                + (if $g then {gas_limit: (.gas_limit // $d.gas_limit)} else {} end)
                + {builder: {enabled: $enabled, gas_limit: (.gas_limit // $d.gas_limit)}}
            )),
            default_config: (
                {fee_recipient: $d.fee_recipient}
                + (if $g then {gas_limit: $d.gas_limit} else {} end)
                + {builder: ({enabled: $enabled, gas_limit: $d.gas_limit} + ($d.builder // {}))}
            )
        }
        + (if $g then {version: 2} else {} end)' /home/charon/vc-config/proposer-config.json >/tmp/prysm-proposer-settings.json
    PROPOSER_SETTINGS+=(--proposer-settings-file="/tmp/prysm-proposer-settings.json")
else
    echo "proposer-config.json not found, running without proposer settings"
fi

# Now run prysm VC.
# --disable-attest-timely: attest at the due time, not early on the block event. Charon
# serves consensus-agreed attestation data just after the due mark; early-attesting pins
# prysm's fetch deadline too tight to receive it ("query until accepted: deadline exceeded").
# --stateless: request the stateless (payload-included) gloas block. A distributed
# validator cannot serve the stateful form, as no single node holds the payload envelope.
exec /app/cmd/validator/validator --wallet-dir="$WALLET_DIR" \
    --accept-terms-of-use=true \
    --datadir="/data/vc" \
    --wallet-password-file="/wallet-password.txt" \
    --enable-beacon-rest-api \
    --monitoring-host=0.0.0.0 \
    --beacon-rest-api-provider="${BEACON_NODE_ADDRESS}" \
    --beacon-rpc-provider="${BEACON_NODE_ADDRESS}" \
    --chain-config-file=/network-config/config.yaml \
    --distributed \
    --disable-attest-timely \
    --stateless \
    "${PROPOSER_SETTINGS[@]}"
