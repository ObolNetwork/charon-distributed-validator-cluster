#!/bin/sh

BUILDER_SELECTION="executiononly"

# If the builder API is enabled, override the builder selection to signal Lodestar to always propose blinded blocks.
if [[ $BUILDER_API_ENABLED == "true" ]];
then
  BUILDER_SELECTION="builderonly"
fi

# for f in /home/charon/validator_keys/keystore-*.json; do
#     echo "Importing key ${f}"

#     # Import keystore with password.
#     node /usr/app/packages/cli/bin/lodestar validator import \
#         --dataDir="/opt/data" \
#         --importKeystores="$f" \
#         --importKeystoresPassword="${f//json/txt}" \
#         --paramsFile="/opt/lodestar/config.yaml"
# done

echo "Imported all keys"

exec node /usr/app/packages/cli/bin/lodestar validator \
    --dataDir="/opt/data" \
    --metrics=true \
    --metrics.address="0.0.0.0" \
    --metrics.port=5065 \
    --beaconNodes="$BEACON_NODE_ADDRESS" \
    --builder="$BUILDER_API_ENABLED" \
    --builder.selection="$BUILDER_SELECTION" \
    --paramsFile="/opt/lodestar/config.yaml" \
    --distributed \
    --useProduceBlockV3=false \
    --logLevel="debug"

