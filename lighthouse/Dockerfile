ARG VERSION

FROM ghcr.io/jqlang/jq:1.8.0 AS jq

FROM ethpandaops/lighthouse:${VERSION}

# jq is used by run.sh to render validator_definitions.yml from the charon proposer config.
COPY --from=jq /jq /usr/local/bin/jq

ENTRYPOINT ["/bin/bash", "/opt/lighthouse/run.sh"]
