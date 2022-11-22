#!/usr/bin/env bash

# Running vouch VC is split into three steps:
# 1. Converting keys into a format which vouch understands. This is what ethdo does.
# 2. Creating configuration for vouch (vouch.yml).
# 3. Actually running the vouch validator client.

baseDir="/opt/charon/node/validator_keys/ethdo"
vouchFile="/opt/charon/node/vouch.yml" # Copy vouch.yml to respective node folder.

# Remove directory if it already exists.
rm -r ${baseDir} || true

# Create a fresh directory for ethdo keys.
mkdir ${baseDir}

# Create an ethdo wallet within the keys folder.
wallet="validators"
/app/ethdo --base-dir="${baseDir}" wallet create --wallet ${wallet}

# Creates vouch configuration (vouch.yml) and updates it with the required data.
function createVouchConfig() {
  rm ${vouchFile}
  cp /opt/charon/vouch/vouch.yml ${vouchFile}

  # Set beacon node addresses.
  addr=${VOUCH_BEACON_NODE_ADDRESS} yq -i '.beacon-node-address = strenv(addr)' ${vouchFile}
}

createVouchConfig

# Import keys into the ethdo wallet.
account=0
for f in /opt/charon/node/validator_keys/keystore-*.json; do
  accountName="account-${account}"
  echo "Importing key ${f} into ethdo wallet: ${wallet}/${accountName}"

  PASSPHRASE=$(cat "${f//json/txt}")
  /app/ethdo \
    --base-dir="${baseDir}" account import \
    --account="${wallet}"/"${accountName}" \
    --keystore="$f" \
    --passphrase="$PASSPHRASE" \
    --keystore-passphrase="$PASSPHRASE"

  # Save the passphrase to vouch.yml.
  id=${account} pass=${PASSPHRASE} yq -i '.accountmanager.wallet.passphrases[env(id)] = strenv(pass)' ${vouchFile}

  # Increment account.
  # shellcheck disable=SC2003
  account=$(expr "$account" + 1)
done

# Log wallet info.
echo "Starting vouch validator client. Wallet info:"
/app/ethdo \
--base-dir=/opt/charon/keys/ethdo wallet info \
--wallet="${wallet}" \
--base-dir="${baseDir}" \
--verbose

# Now run vouch.
exec /app/vouch --base-dir=/opt/charon/node
