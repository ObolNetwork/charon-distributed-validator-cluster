#!/usr/bin/env bash

# Generates the inputs required for the DKG ceremony.
# Call via make: make dkg

CMD=${1}
N=${2}
T=${3}

echo "Creating enrs (p2pkeys) for ${N} nodes"
ENRS=""
for i in $( eval echo {0..$N} ); do
  [ "${i}" == "$N" ] && break

  ENR=$($CMD gen-p2pkey --data-dir=/charon-docker-compose/node${i} | grep enr)
  [ "${i}" != "0" ] && ENRS+=","
  ENRS+=$ENR
done

echo "Creating cluster_definition.json file"
$CMD create dkg --output-dir=/charon-docker-compose --num-validators=2 --threshold=${T} --operator-enrs=${ENRS} --dkg-algorithm=frost

grep -q dkg .env || (printf "\n# Delete this file to revert to charon run command\nCOMPOSE_COMMAND=dkg\n" >> ".env")
