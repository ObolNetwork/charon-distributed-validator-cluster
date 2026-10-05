ARG VERSION

FROM ghcr.io/jqlang/jq:1.8.2 AS jq

FROM offchainlabs/prysm-validator:${VERSION}

# jq is used by run.sh to render Prysm's proposer settings from charon's proposer-config.json.
COPY --from=jq /jq /usr/local/bin/jq
