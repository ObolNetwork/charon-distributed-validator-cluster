#!/bin/sh

geth init  --datadir /db /config/genesis.json

bootnodes=$(cat /config/enodes.list)
network_id=$(jq -r '.config.chainId' /config/genesis.json)

exec geth \
  --datadir=/db \
  --networkid="$network_id" \
  --syncmode=full \
  --verbosity=${EL_LOG_LEVL:-3} \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.vhosts=* \
  --http.api="db,eth,net,engine,rpc,web3" \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret="/config/jwtsecret" \
  --port=${EL_P2P_PORT:-30303} \
  --bootnodes="$bootnodes" \
  --metrics \
  --metrics.addr=0.0.0.0 \
  --metrics.port=6060
  