#!/usr/bin/env bash

# Docker creates missing bind mount directories as root. Start as root only to
# hand /home/user/data to uid 1000, then re-run this script as uid 1000.
if [ "$(id -u)" = "0" ]; then
  chown -R 1000:1000 /home/user/data
  chmod 700 /home/user/data
  HOME="$(getent passwd 1000 | cut -d: -f6)" exec setpriv --reuid=1000 --regid=1000 --init-groups "$0" "$@"
fi

# Remove previously imported keys, but keep the slashing protection DB
# (validators/slashing_protection.sqlite3*) across restarts.
rm -rf /home/user/data/${NODE}/secrets /home/user/data/${NODE}/validators/0x*

# Refer: https://nimbus.guide/keys.html
# Running a nimbus VC involves two steps which need to run in order:
# 1. Importing the validator keys
# 2. And then actually running the VC
tmpkeys="/home/validator_keys/tmpkeys"
mkdir -p ${tmpkeys}

for f in /home/validator_keys/keystore-*.json; do
  echo "Importing key ${f}"

  # Read password from keystore-*.txt into $password variable.
  password=$(<"${f//json/txt}")

  # Copy keystore file to tmpkeys/ directory.
  cp "${f}" "${tmpkeys}"

  # Import keystore with the password.
  echo "$password" | \
  /home/user/nimbus_beacon_node deposits import \
  --data-dir=/home/user/data/${NODE} \
  /home/validator_keys/tmpkeys

  # Delete tmpkeys/keystore-*.json file that was copied before.
  filename="$(basename ${f})"
  rm "${tmpkeys}/${filename}"
done

# Delete the tmpkeys/ directory since it's no longer needed.
rm -r ${tmpkeys}

echo "Imported all keys"

# On a fresh setup charon writes proposer-config.json shortly after it starts, wait for it.
PROPOSER_CONFIG="/opt/charon/node/vc-config/proposer-config.json"
for _ in $(seq 60); do
  [ -f "${PROPOSER_CONFIG}" ] && break
  sleep 2
done

# Render the per-validator proposer settings from charon's proposer-config.json:
# entries only carry fields diverging from default_config, absent fields fall back
# to it. Without it, Nimbus falls back to --suggested-fee-recipient.
if [ -f "${PROPOSER_CONFIG}" ]; then
  echo "proposer-config.json found, rendering per-validator proposer settings"
  for f in /home/validator_keys/keystore-*.json; do
    pubkey="0x$(jq -r .pubkey "${f}")"
    dir="/home/user/data/${NODE}/validators/${pubkey}"

    jq -r --arg pk "${pubkey}" '.proposer_config[$pk].fee_recipient // .default_config.fee_recipient' "${PROPOSER_CONFIG}" >"${dir}/suggested_fee_recipient.hex"
    jq -r --arg pk "${pubkey}" '.proposer_config[$pk].gas_limit // .default_config.gas_limit' "${PROPOSER_CONFIG}" >"${dir}/suggested_gas_limit.json"
  done
else
  echo "proposer-config.json not found, using FEE_RECIPIENT for all validators"
fi

# Now run nimbus VC
# Note: Nimbus has no flag to request the stateless (payload-included) form of gloas block
# production; it requests it only when configured with more than one beacon node. Behind charon
# (a single beacon node endpoint) it requests the stateful form, which a distributed validator
# cannot complete, so it cannot propose gloas blocks today.
exec /home/user/nimbus_validator_client \
  --data-dir=/home/user/data/"${NODE}" \
  --beacon-node="http://$NODE:3600" \
  --doppelganger-detection=false \
  --metrics \
  --metrics-address=0.0.0.0 \
  --suggested-fee-recipient="${FEE_RECIPIENT}" \
  --payload-builder="${BUILDER_API_ENABLED}" \
  --distributed
