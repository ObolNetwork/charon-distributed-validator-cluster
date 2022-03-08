#!/usr/bin/env sh

# Support locally built charon binaries
PATH="/charon:${PATH}"
if [ "$(which charon)" == "/charon/charon" ]; then
  echo "Running locally built charon binary"
fi

# If CLEAN env var true, clean existing manifest and p2pkeys.
if [ "${CLEAN}" = "true" ]; then
  echo "Cleaning cluster manifest and p2pkeys"
  rm /charon/manifest.json 2>/dev/null || true
  rm /charon/node*/p2pkey 2>/dev/null || true
fi

# If GENERATE env var true and manifest doesn't exist, generate a simnet cluster
if [ "${GENERATE}" = "true" ] && [ ! -f "/charon/manifest.json" ]; then
  echo "Generating simnet cluster"
  charon gen-simnet -t=3 -n=4 --cluster-dir=/tmp/charon-simnet/ 1>/dev/null
  cp /tmp/charon-simnet/manifest.json /charon/manifest.json
  cp -r /tmp/charon-simnet/node* /charon/
  rm /charon/node*/run.sh
fi

# Get container IP (https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x)
BIND=$(ip route get 1 | awk '{print $NF;exit}')

# Write a config file: charon.yml
cat <<EOF > charon.yml

data-dir: ${PWD}
manifest-file: /charon/manifest.json
monitoring-address: ${BIND}:16001
validator-api-address: ${BIND}:16002
p2p-tcp-address: ${BIND}:16003
p2p-udp-address: ${BIND}:16004
EOF

# If BOOTNODE env var present, resolve ENR via curl/wget
if [ -n "${BOOTNODE}" ]; then
  while ! ENR=$(wget -qO- "http://${BOOTNODE}:16001/enr" 2>/dev/null); do
    echo "waiting for http://${BOOTNODE}:16001/enr to become available..."
    sleep 1
  done
  echo "p2p-bootnodes: '${ENR}'" >> charon.yml
fi

# Run charon
exec charon run
