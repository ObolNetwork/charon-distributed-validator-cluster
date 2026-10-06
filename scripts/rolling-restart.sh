#!/usr/bin/env bash

# Restarts charon nodes one at a time, keeping the cluster above threshold. Before and after each
# restart it waits until every node reports ready on its /readyz monitoring endpoint, and stops on
# the first node that doesn't become ready.
#
# Usage: scripts/rolling-restart.sh [--with-vcs] [--force-recreate] [--timeout SECONDS] [node...]
#
#   --with-vcs        also restart each node's validator client (vcN-*) together with the node.
#   --force-recreate  recreate containers even if their configuration and image didn't change,
#                     e.g. to pick up changed validator client scripts.
#   --timeout         seconds to wait for all nodes to be ready, defaults to 900.
#   node...           nodes to restart in order, e.g. node3 node5, defaults to all nodes.
#
# Run it from the repository root after pulling the latest changes, e.g.:
#   git pull && scripts/rolling-restart.sh

set -euo pipefail

with_vcs=false
up_args=(-d)
timeout=900
nodes=()

while [ $# -gt 0 ]; do
  case "$1" in
    --with-vcs) with_vcs=true ;;
    --force-recreate) up_args+=(--force-recreate) ;;
    --timeout) timeout="$2"; shift ;;
    -h|--help) sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    node[0-9]*) nodes+=("$1") ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

services=$(docker compose config --services)
all_nodes=($(grep -E '^node[0-9]+$' <<<"$services" | sort -V))

if [ ${#all_nodes[@]} -eq 0 ]; then
  echo "No charon nodes found, run this from the repository root" >&2
  exit 1
fi

if [ ${#nodes[@]} -eq 0 ]; then
  nodes=("${all_nodes[@]}")
fi

# Prints the nodes that aren't ready, returns non-zero if any.
not_ready() {
  local bad="" node resp
  for node in "${all_nodes[@]}"; do
    resp=$(docker compose exec -T "$node" wget -qO- -T 5 http://localhost:3620/readyz 2>&1 | head -1 || true)
    [ "$resp" = "ok" ] || bad="$bad $node=${resp:-unreachable}"
  done
  [ -z "$bad" ] || { echo "$bad"; return 1; }
}

# Waits until all nodes are ready, exits if they aren't within the timeout.
wait_ready() {
  local start=$SECONDS bad
  while ! bad=$(not_ready); do
    if [ $((SECONDS - start)) -ge "$timeout" ]; then
      echo "Nodes not ready after ${timeout}s:$bad, stopping" >&2
      exit 1
    fi
    sleep 10
  done
  echo "All nodes ready after $((SECONDS - start))s"
}

for node in "${nodes[@]}"; do
  grep -qx "$node" <<<"$services" || { echo "Unknown node: $node" >&2; exit 1; }
done

# Pull images first, so each node is only down for its restart.
pull=("${nodes[@]}")
if $with_vcs; then
  for node in "${nodes[@]}"; do
    pull+=($(grep -E "^vc${node#node}-" <<<"$services" || true))
  done
fi
docker compose pull "${pull[@]}"

echo "Checking all nodes are ready before restarting"
wait_ready

for node in "${nodes[@]}"; do
  restart=("$node")
  if $with_vcs; then
    restart+=($(grep -E "^vc${node#node}-" <<<"$services" || true))
  fi

  echo "Restarting ${restart[*]}"
  # Never run "docker compose up -d" without services, it would restart all nodes at once.
  docker compose up "${up_args[@]}" "${restart[@]}"

  sleep 10
  wait_ready
done

echo "Restarted ${nodes[*]}"
