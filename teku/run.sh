#!/usr/bin/env bash

# Docker creates missing bind mount directories as root. Start as root only to
# hand /home/data to uid 1000, then re-run this script as uid 1000.
if [ "$(id -u)" = "0" ]; then
  chown -R 1000:1000 /home/data
  chmod 700 /home/data
  HOME="$(getent passwd 1000 | cut -d: -f6)" exec setpriv --reuid=1000 --regid=1000 --init-groups "$0" "$@"
fi

# On a fresh setup charon writes proposer-config.json shortly after it starts, wait for it.
PROPOSER_CONFIG="/opt/charon/node/vc-config/proposer-config.json"
for _ in $(seq 60); do
  [ -f "${PROPOSER_CONFIG}" ] && break
  sleep 2
done

# Render Teku's proposer config from charon's: entries only carry fields diverging
# from default_config, absent fields fall back to it. Without it, Teku falls back to
# --validators-proposer-default-fee-recipient.
if [ -f "${PROPOSER_CONFIG}" ]; then
  echo "proposer-config.json found, rendering teku proposer config"
  jq --argjson enabled "${BUILDER_API_ENABLED}" '
    .default_config as $d |
    {
      proposer_config: (.proposer_config | map_values({
        fee_recipient: (.fee_recipient // $d.fee_recipient),
        builder: {enabled: $enabled, gas_limit: (.gas_limit // $d.gas_limit)}
      })),
      default_config: {
        fee_recipient: $d.fee_recipient,
        builder: {enabled: $enabled, gas_limit: $d.gas_limit}
      }
    }' "${PROPOSER_CONFIG}" >/tmp/teku-proposer-config.json
  set -- "$@" --validators-proposer-config=/tmp/teku-proposer-config.json
else
  echo "proposer-config.json not found, using FEE_RECIPIENT for all validators"
fi

exec /opt/teku/bin/teku "$@"
