#!/bin/sh
# Nimbus validator client entrypoint for the Platåberget devnet.
# Uses the ethpandaops/nimbus-eth2 devnet image (gloas-capable). That image's
# binary paths differ from the upstream statusim image, so locate them at
# runtime. The validator client derives the network spec from the beacon node
# (the local charon node), so no testnet-dir is needed here.
set -e

# Locate the beacon-node (used for the deposits-import tool) and the VC binary.
BN=$(command -v nimbus_beacon_node || true)
[ -z "${BN}" ] && [ -x /home/user/nimbus_beacon_node ] && BN=/home/user/nimbus_beacon_node
[ -z "${BN}" ] && [ -x /usr/local/bin/nimbus_beacon_node ] && BN=/usr/local/bin/nimbus_beacon_node

VC=$(command -v nimbus_validator_client || true)
[ -z "${VC}" ] && [ -x /home/user/nimbus_validator_client ] && VC=/home/user/nimbus_validator_client
[ -z "${VC}" ] && [ -x /usr/local/bin/nimbus_validator_client ] && VC=/usr/local/bin/nimbus_validator_client

echo "nimbus beacon_node: ${BN:-NOT FOUND}"
echo "nimbus validator_client: ${VC:-NOT FOUND}"

# Cleanup nimbus data dir if it already exists.
rm -rf "/home/user/data/${NODE}"

# Import the validator keys (nimbus imports via the beacon-node deposits tool).
tmpkeys="/home/validator_keys/tmpkeys"
mkdir -p "${tmpkeys}"

for f in /home/validator_keys/keystore-*.json; do
  echo "Importing key ${f}"
  # Read password from the sibling keystore-*.txt.
  password=$(cat "${f%.json}.txt")
  cp "${f}" "${tmpkeys}"
  echo "${password}" | "${BN}" deposits import \
    --data-dir="/home/user/data/${NODE}" \
    "${tmpkeys}"
  rm "${tmpkeys}/${f##*/}"
done

rm -r "${tmpkeys}"
echo "Imported all keys"

exec "${VC}" \
  --data-dir="/home/user/data/${NODE}" \
  --beacon-node="http://${NODE}:3600" \
  --doppelganger-detection=false \
  --metrics \
  --metrics-address=0.0.0.0 \
  --distributed
