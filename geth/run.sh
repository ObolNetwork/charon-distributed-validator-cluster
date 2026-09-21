#!/bin/sh
# Execution-layer entrypoint for the Platåberget (glamsterdam-devnet-8) devnet.
# geth needs a one-time init from the devnet genesis.json, then runs with the
# devnet EL bootnodes (read from the mounted network-config/enodes.txt).
set -e

DATADIR=/data
GENESIS=/network-config/genesis.json

if [ ! -d "${DATADIR}/geth/chaindata" ]; then
  echo "Initialising geth datadir from ${GENESIS}"
  geth init --datadir="${DATADIR}" "${GENESIS}"
fi

# Join the enode list into a single comma-separated --bootnodes value.
BOOTNODES=$(tr '\n' ',' < /network-config/enodes.txt | sed 's/,*$//')

exec geth \
  --datadir="${DATADIR}" \
  --networkid=7091047534 \
  --bootnodes="${BOOTNODES}" \
  --syncmode=full \
  --http --http.addr=0.0.0.0 --http.port=8545 \
  --http.api=eth,net,web3,engine,admin --http.vhosts="*" --http.corsdomain="*" \
  --authrpc.addr=0.0.0.0 --authrpc.port=8551 --authrpc.vhosts="*" \
  --authrpc.jwtsecret=/opt/jwt/jwt.hex \
  --metrics --metrics.addr=0.0.0.0 --metrics.port=6060 \
  --port=30303
