#!/usr/bin/env bash

while ! curl "http://${NODE}:16002/up" 2>/dev/null; do
  echo "Waiting for http://${NODE}:16002/up to become available..."
  sleep 5
done

echo "Creating testnet config"
rm -rf /tmp/testnet || true
mkdir /tmp/testnet/
curl "http://${NODE}:16002/eth/v1/config/spec" | jq -r .data | yq -P > /tmp/testnet/config.yaml
echo "0" > /tmp/testnet/deploy_block.txt

for f in /opt/charon/"${NODE}"/keystore-*.json; do
  echo "Importing key ${f}"
  cat "$(echo "${f}" | sed 's/json/txt/')" | lighthouse account validator import \
    --testnet-dir "/tmp/testnet" \
    --stdin-inputs \
    --keystore "${f}"
done


echo "Starting lighthouse validator client for ${NODE}"
exec lighthouse validator \
  --testnet-dir "/tmp/testnet" \
  --beacon-node "http://${NODE}:16002" \
  --suggested-fee-recipient "0xC62188bDB24d2685AEd8fa491E33eFBa47Db63C2"

