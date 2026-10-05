FROM ghcr.io/jqlang/jq:1.8.2 AS jq

FROM statusim/nimbus-eth2:multiarch-v26.10.0 as nimbusbn

FROM statusim/nimbus-validator-client:multiarch-v26.10.0

COPY --from=nimbusbn /home/user/nimbus_beacon_node /home/user/nimbus_beacon_node

# jq is used by run.sh to render the per-validator proposer settings from charon's proposer-config.json.
COPY --from=jq /jq /usr/local/bin/jq

ENTRYPOINT ["/home/user/data/run.sh"]
