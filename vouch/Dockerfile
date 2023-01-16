FROM wealdtech/ethdo:1.26.3 as ethdo

FROM attestant/vouch:1.6.3

COPY --from=ethdo /app/ethdo /app/ethdo

RUN apt-get update && apt-get install -y curl jq wget

ENTRYPOINT ["/opt/vouch/run.sh"]