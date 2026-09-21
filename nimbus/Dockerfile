ARG BN_VERSION
ARG VC_VERSION

# Gloas-capable beacon node, used only for its keystore `deposits import` tool.
FROM ethpandaops/nimbus-eth2:${BN_VERSION} AS nimbusbn

# Nimbus validator client (the ethpandaops nimbus-eth2 image ships the beacon node only).
FROM statusim/nimbus-validator-client:${VC_VERSION}

COPY --from=nimbusbn /home/user/nimbus-eth2/build/nimbus_beacon_node /home/user/nimbus_beacon_node

# jq is used by run.sh to render per-validator proposer settings from the charon proposer config.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/sh", "/opt/nimbus/run.sh"]
