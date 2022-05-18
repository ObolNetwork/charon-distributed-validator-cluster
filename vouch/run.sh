#!/usr/bin/env bash

# Create an ethdo wallet within the keys folder
mkdir /opt/charon/keys/ethdo || true
/app/ethdo --base-dir=/opt/charon/keys/ethdo wallet create --wallet "test" || true

keystore=0
for f in /opt/charon/keys/keystore-*.json; do
  echo "Importing key ${f} into ethdo wallet: test/${keystore}"  
  PASS=$(cat "$(echo "${f}" | sed 's/json/txt/')")
  /app/ethdo --base-dir=/opt/charon/keys/ethdo account import --account=test/$keystore --keystore=$f --passphrase=$PASS --keystore-passphrase=$PASS || true
  keystore=$(expr $keystore + 1)
done


# Now run vouch
echo "Starting vouch validator client. Wallet info:"
/app/ethdo --base-dir=/opt/charon/keys/ethdo wallet info --wallet "test" 
exec /app/vouch --base-dir=/opt/charon/vouch
