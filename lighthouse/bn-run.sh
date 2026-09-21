#!/bin/sh
# Lighthouse beacon-node entrypoint for the Platåberget devnet.
# The devnet bootnodes are passed explicitly via --boot-nodes (reading them from
# the testnet-dir alone did not seed discovery), and --disable-packet-filter is
# set because the host is behind a NAT with no UPnP, which otherwise starves
# discv5 of peers.
set -e

BOOT=$(tr '\n' ',' < /network-config/bootstrap_nodes.txt | sed 's/,*$//')

exec lighthouse bn \
  --testnet-dir=/network-config \
  --boot-nodes="${BOOT}" \
  --disable-packet-filter \
  --checkpoint-sync-url="${CHECKPOINT_SYNC_URL:-https://checkpoint-sync.plataberget.ethpandaops.io}" \
  --execution-endpoint=http://geth:8551 \
  --execution-jwt=/opt/jwt/jwt.hex \
  --datadir=/opt/app/beacon/ \
  --debug-level=info \
  --http \
  --http-address=0.0.0.0 \
  --http-port=5052 \
  --metrics \
  --metrics-address=0.0.0.0 \
  --metrics-port=5054 \
  --metrics-allow-origin="*"
