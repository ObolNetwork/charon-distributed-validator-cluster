FROM wealdtech/ethdo:1.25.3 as ethdo

FROM attestant/vouch:1.6.2

COPY --from=ethdo /app/ethdo /app/ethdo

RUN apt-get update && apt-get install -y curl jq wget

ENV YQ_VERSION=v4.28.1
ENV YQ_BINARY=yq_linux_amd64
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/bin/yq \
    && chmod +x /usr/bin/yq

ENTRYPOINT ["/opt/config/run.sh"]