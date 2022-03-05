#!/usr/bin/env bash

set -e

# Build a local charon binary to run in the docker container (instead of official release).
# This is useful for local testing and debugging.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

if [ "${CHARON_REPO}" != "" ]; then
  # Either use the provided a path to the charon repo
  cd "${CHARON_REPO}"
else
  # Or assume it is next to this repo.
  cd "${SCRIPT_DIR}/../charon"
fi

MSG="Source: $(git log --pretty=oneline -1)"
if [[ $(git diff --stat) != '' ]]; then
  MSG="${MSG} (dirty)"
fi
echo "${MSG}"
echo "Target: ${SCRIPT_DIR}/charon"

GOOS=linux GOARCH=amd64 go build -o "${SCRIPT_DIR}/charon"
cd - &> /dev/null
