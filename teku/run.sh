#!/usr/bin/env bash

while ! curl "http://${NODE}:16002/up" 2>/dev/null; do
  echo "Waiting for http://${NODE}:16002/up to become available..."
  sleep 5
done

echo "Importing simnet keys /charon/${NODE}/keystore-simnet-0.json"
echo "simnet" > "/charon/${NODE}/keystore-simnet-0.txt"

echo "Starting teku validator client for ${NODE}"
exec /opt/teku/bin/teku validator-client \
  --network=auto \
  --beacon-node-api-endpoint="http://${NODE}:16002" \
  --validator-keys="/charon/${NODE}:/charon/${NODE}"

