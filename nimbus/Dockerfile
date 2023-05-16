FROM statusim/nimbus-eth2:multiarch-v23.5.0 as nimbusbn

FROM statusim/nimbus-validator-client:multiarch-v23.5.0

COPY --from=nimbusbn /home/user/nimbus_beacon_node /home/user/nimbus_beacon_node

ENTRYPOINT ["/home/user/data/run.sh"]