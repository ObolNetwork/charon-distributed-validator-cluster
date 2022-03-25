#!/usr/bin/env bash

while ! curl "http://${NODE}:16002/up" 2>/dev/null; do
  echo "Waiting for http://${NODE}:16002/up to become available..."
  sleep 5
done

echo "Creating simnet config"
rm -rf /tmp/simnet || true
mkdir /tmp/simnet/
curl "http://${NODE}:16002/eth/v1/config/spec" | jq -r .data | yq -P > /tmp/simnet/config.yaml
echo "0" > /tmp/simnet/deploy_block.txt

echo "Importing simnet keys /charon/${NODE}/keystore-simnet-0.json"
echo "simnet" | lighthouse account validator import \
  --testnet-dir "/tmp/simnet" \
  --stdin-inputs \
  --keystore "/charon/${NODE}/keystore-simnet-0.json"

echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse validator \
  --testnet-dir "/tmp/simnet" \
  --beacon-node "http://${NODE}:16002"
