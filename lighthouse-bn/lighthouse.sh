#!/bin/sh

if [ -n "${CHECKPOINT_SYNC_URL}" ]; then
  checkpoint_sync="--checkpoint-sync-url=${CHECKPOINT_SYNC_URL}"
else
  checkpoint_sync=""
fi

exec lighthouse bn \
  --datadir=/data/beacon \
  --execution-jwt=/config/jwtsecret \
  --execution-endpoint=http://geth:8551 \
  --self-limiter=blob_sidecars_by_range:256/10 \
  --debug-level=${CL_LOG_LEVEL:-info} \
  --testnet-dir=/config/testnet \
  --http \
  --http-address=0.0.0.0 \
  --http-port=5052  \
  --metrics \
  --metrics-address=0.0.0.0 \
  --metrics-port=5054 \
  --metrics-allow-origin="*" \
  --port=${CL_P2P_PORT:-9000} \
  ${checkpoint_sync} \
  --disable-peer-scoring
