#!/usr/bin/env bash

while ! curl "http://${NODE}:16002/up" 2>/dev/null; do
  echo "Waiting for http://${NODE}:16002/up to become available..."
  sleep 5
done

echo "Importing simnet keys /charon/${NODE}/keystore-simnet-0.json"
echo "simnet" | lighthouse account validator import \
  --network prater \
  --stdin-inputs \
  --keystore "/charon/${NODE}/keystore-simnet-0.json"

echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse validator \
  --network prater \
  --beacon-node "http://${NODE}:16002"
