#!/usr/bin/env sh

# Get container IP (https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x)
BIND=`ip route get 1 | awk '{print $NF;exit}'`

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
  while ! ENR=$(wget -qO- http://${BOOTNODE}:16001/enr); do
    sleep 1
  done
  echo "p2p-udp-bootnodes: '${ENR}'" >> charon.yml
fi

charon run