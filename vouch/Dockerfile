FROM wealdtech/ethdo:1.39.1 as ethdo

FROM attestant/vouch:1.13.1

COPY --from=ethdo /app/ethdo /app/ethdo

RUN apt-get update && apt-get install -y curl jq wget

ENTRYPOINT ["/opt/vouch/run.sh"]