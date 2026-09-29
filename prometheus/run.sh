#!/bin/sh

# Renders prometheus.yml from prometheus.yml.example at start, substituting the Obol
# hosted-monitoring token from the environment (PROM_REMOTE_WRITE_TOKEN in .env), so the
# secret never has to be written into a tracked file. Mirrors charon-distributed-validator-node.

if [ -z "$PROM_REMOTE_WRITE_TOKEN" ]
then
  echo "\$PROM_REMOTE_WRITE_TOKEN variable is empty" >&2
  exit 1
fi

sed -e "s|\$PROM_REMOTE_WRITE_TOKEN|${PROM_REMOTE_WRITE_TOKEN}|g" \
    /etc/prometheus/prometheus.yml.example > /etc/prometheus/prometheus.yml

exec /bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml
