# BN_VERSION is retained for compose build-arg compatibility but no longer used:
# the nightly tarball below supplies both the validator client and the beacon
# node (used only for its keystore `deposits import` tool).
ARG BN_VERSION
ARG VC_VERSION

# Dated nimbus nightly asset (built from unstable HEAD), pinned for reproducibility.
# The statusim RELEASE VC (v26.8.0) cannot parse the glamsterdam-devnet-8 spec and
# fails initTimeConfig ("Could not obtain time configuration parameters", see
# status-im/nimbus-eth2#8833); the unstable/nightly build tracks the devnet spec.
ARG VC_NIGHTLY=nimbus-eth2_Linux_amd64_20260928_09533a8b.tar.gz

FROM debian:bookworm-slim AS nightly
ARG VC_NIGHTLY
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /dl
RUN curl -fsSL "https://github.com/status-im/nimbus-eth2/releases/download/nightly/${VC_NIGHTLY}" -o n.tar.gz \
    && tar xzf n.tar.gz --strip-components=2 --wildcards '*/build/nimbus_validator_client' '*/build/nimbus_beacon_node' \
    && chmod +x nimbus_validator_client nimbus_beacon_node \
    && ./nimbus_validator_client --version | head -1

# Runtime environment from the statusim image; its binaries are replaced with the
# glamsterdam-capable nightly builds below.
FROM statusim/nimbus-validator-client:${VC_VERSION}

COPY --from=nightly /dl/nimbus_validator_client /home/user/nimbus_validator_client
COPY --from=nightly /dl/nimbus_beacon_node /home/user/nimbus_beacon_node

# jq is used by run.sh to render per-validator proposer settings from the charon proposer config.
USER root
RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/sh", "/opt/nimbus/run.sh"]
