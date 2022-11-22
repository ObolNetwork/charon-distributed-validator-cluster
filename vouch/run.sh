#!/usr/bin/env bash

# Running vouch VC is split into three steps:
# 1. Converting keys into a format which vouch understands. This is what ethdo does.
# 2. Creating configuration for vouch (vouch.yml).
# 3. Actually running the vouch validator client.

baseDir="/opt/vouch"
vouchFile="/opt/vouch/vouch.yml"
keysDir="/opt/vouch/keys"

# Create an ethdo wallet within the keys folder.
wallet="validators"
/app/ethdo --base-dir="${keysDir}" wallet create --wallet ${wallet}

# Copy vouch.yml to modify with beacon address
cp /opt/config/vouch.yml ${vouchFile}

# Set beacon node addresses into vouch.yml.
yq -i '.beacon-node-address = strenv(VOUCH_BEACON_NODE_ADDRESS)' ${vouchFile}

# Import keys into the ethdo wallet.
account=0
for f in /opt/validator_keys/keystore-*.json; do
  accountName="account-${account}"
  echo "Importing key ${f} into ethdo wallet: ${wallet}/${accountName}"

  KEYSTORE_PASSPHRASE=$(cat "${f//json/txt}")
  ACCOUNT_PASSPHRASE="T8BFYJZU5R" # Hardcoded ethdo account passphrase
  /app/ethdo \
    --base-dir="${keysDir}" account import \
    --account="${wallet}"/"${accountName}" \
    --keystore="$f" \
    --passphrase="$ACCOUNT_PASSPHRASE" \
    --keystore-passphrase="$KEYSTORE_PASSPHRASE"

  # Increment account.
  # shellcheck disable=SC2003
  account=$(expr "$account" + 1)
done

# Log wallet info.
echo "Starting vouch validator client. Wallet info:"
/app/ethdo \
--base-dir=${keysDir} wallet info \
--wallet="${wallet}" \
--base-dir="${keysDir}" \
--verbose

# Now run vouch.
exec /app/vouch --base-dir=${baseDir}
