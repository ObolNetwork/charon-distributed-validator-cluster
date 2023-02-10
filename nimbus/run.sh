#!/usr/bin/env bash

# Refer: https://nimbus.guide/keys.html
# Running a nimbus VC involves two steps which need to run in order:
# 1. Importing the validator keys
# 2. And then actually running the VC
for f in /home/validator_keys/keystore-*.json; do
  echo "Importing key ${f}"
  password=$(<"${f//json/txt}")
  echo "$password" | \
  /home/user/nimbus_beacon_node deposits import \
  --data-dir=/home/user/data/${NODE} \
  /home/validator_keys
done

echo "Imported keys"

# Now run nimbus VC
exec /home/user/nimbus_validator_client --data-dir=/home/user/data/${NODE} --beacon-node=${BEACON_NODE_ADDRESS}
