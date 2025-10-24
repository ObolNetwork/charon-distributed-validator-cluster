FROM statusim/nimbus-eth2:multiarch-v25.9.2 as nimbusbn

FROM statusim/nimbus-validator-client:multiarch-v25.9.2

COPY --from=nimbusbn /home/user/nimbus_beacon_node /home/user/nimbus_beacon_node

ENTRYPOINT ["/home/user/data/run.sh"]
