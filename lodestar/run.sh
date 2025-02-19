#!/bin/sh

tmpkeys="/home/validator_keys/tmpkeys"
mkdir -p ${tmpkeys}

for f in /home/charon/validator_keys/keystore-*.json; do
    echo "Importing key ${f}"

    # Copy keystore file to tmpkeys/ directory.
    cp "${f}" "${tmpkeys}"

    # Import keystore with password.
    node /usr/app/packages/cli/bin/lodestar validator import \
        --network="$ETH2_NETWORK" \
        --importKeystores="/home/charon/validator_keys" \
        --importKeystoresPassword="${f//json/txt}"

    # Delete tmpkeys/keystore-*.json file that was copied before.
    filename="$(basename ${f})"
    rm "${tmpkeys}/${filename}"
done

# Delete the tmpkeys/ directory since it's no longer needed.
rm -r ${tmpkeys}

echo "Imported all keys"

node /usr/app/packages/cli/bin/lodestar validator \
    --network="$ETH2_NETWORK" \
    --metrics=true \
    --metrics.address="0.0.0.0" \
    --metrics.port=5064 \
    --beaconNodes="$BEACON_NODE_ADDRESS" \
    --distributed