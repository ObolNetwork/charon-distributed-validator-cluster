ARG VERSION

FROM ghcr.io/jqlang/jq:1.8.0 AS jq

# Gloas-capable prysm validator client, the build the Platåberget devnet runs.
FROM ethpandaops/prysm-validator:${VERSION}

# jq is used by run.sh to render Prysm's proposer settings from the charon-generated config.
COPY --from=jq /jq /usr/local/bin/jq
