#!/usr/bin/env sh

# Support locally built charon binaries
PATH="/charon:${PATH}"
if [ "$(which charon)" = "/charon/charon" ]; then
  echo "Running locally built charon binary"
fi

# Get container IP (https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x)
BIND=$(ip route get 1 | awk '{print $NF;exit}')

# Write a config file: charon.yml
cat <<EOF > charon.yml
data-dir: ${PWD}
bootnode-http-address: ${BIND}:16001
p2p-udp-address: ${BIND}:16004
EOF

# If p2p key doesn't exist yet, create it.
if [ ! -f "p2pkey" ]; then
  charon gen-p2pkey
fi

# Run bootnode
exec charon bootnode
