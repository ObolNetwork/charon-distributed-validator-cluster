FROM statusim/nimbus-eth2:multiarch-v23.1.1 as nimbusbn

FROM statusim/nimbus-validator-client:multiarch-v23.1.1

COPY --from=nimbusbn /home/user/nimbus_beacon_node /home/user/nimbus_beacon_node

USER root

RUN apt-get update

ENTRYPOINT ["/home/user/data/run.sh"]