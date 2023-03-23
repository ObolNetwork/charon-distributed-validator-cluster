ARG NIMBUS_VERSION

FROM statusim/nimbus-eth2:multiarch-$NIMBUS_VERSION as nimbusbn

FROM statusim/nimbus-validator-client:multiarch-$NIMBUS_VERSION

COPY --from=nimbusbn /home/user/nimbus_beacon_node /home/user/nimbus_beacon_node

ENTRYPOINT ["/home/user/data/run.sh"]