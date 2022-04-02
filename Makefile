# Use locally built charon if present
entrypoint := $(if $(wildcard charon),/charon/charon,/usr/local/bin/charon)

# TODO(corverr): Replace with static version 0.3.0
charon_cmd := docker run --rm --entrypoint=$(entrypoint) -v $(shell pwd):/charon ghcr.io/obolnetwork/charon/charon:latest

# Default cluster. Override example: make t=4 n=5 gen-cluster
n := 4
t := 3

.DEFAULT_GOAL := help
.PHONY: help
help:
	@echo "The following *make* targets are available:"
	@echo " up               Create and start docker-compose containers"
	@echo " down             Stop and remove docker-compose resources"
	@echo " gen-cluster      Generates a simnet cluster"
	@echo " build-local      Build local charon binary from source (instead of using binary in container)"
	@echo " clean            Cleans previously generated cluster"
	@echo ""
	@echo "Targets only for the brave ⚔️ 🐉:"
	@echo " disable-simnet         Disables simnet mock beacon node and configures real beacon node endpoint"
	@echo " split-existing-keys    Create a cluster by splitting existing non-dvt validator keys"

.PHONY: up
up:
	if [ ! -f "manifest.json" ]; then echo "Cluster not created yet" && exit 1; fi
	docker-compose up

.PHONY: down
down:
	docker-compose down

.PHONY: clean
clean:
	@echo "docker-compose down" && docker-compose down 1>/dev/null
	@echo "Cleaning cluster manifest, node config and node keys"
	@rm -f manifest.json 2>/dev/null || true
	@rm -f node*/* 2>/dev/null || true
	@rm -f bootnode/* 2>/dev/null || true
	@rm -rf lighthouse/*/ 2>/dev/null || true
	@[ -f charon ] && echo "Deleting locally built charon binary" || true
	@rm charon 2>/dev/null || true
	@rm .env 2>/dev/null || true
	@[ -f beaconnode.env.old ] && echo "Enabling simnet" && mv beaconnode.env.old beaconnode.env || true
	@echo "Pulling latest container" && docker pull ghcr.io/obolnetwork/charon/charon:latest 1>/dev/null

.PHONY: build-local
build-local:
	@./build_local.sh

.PHONY: gen-cluster
gen-cluster:
	@echo "Generating simnet cluster (may take a moment...)"
	$(charon_cmd) gen-cluster --clean=false -t=$(t) -n=$(n) --cluster-dir=/charon 1>/dev/null
	@make post-gen-cluster

.PHONY: split-existing-keys
split-existing-keys:
	@if [ ! -f split_keys/keystore*.json ]; then echo "No keys in split_keys/ directory" && exit 1; fi
	@echo "Generating cluster by splitting existing validator keys (may take a moment...)"
	$(charon_cmd) gen-cluster --split-existing-keys --keys-dir=/charon/split_keys --clean=false -t=$(t) -n=$(n) --cluster-dir=/charon 1>/dev/null
	@echo "***************** WARNING: Splitting keys **********************"
	@echo " Please make sure any existing validator has been shut down for"
	@echo " at least 2 finalised epochs before starting the charon cluster,"
	@echo " otherwise slashing could occur."
	@echo "****************************************************************"
	@make post-gen-cluster

.PHONY: post-gen-cluster
post-gen-cluster:
	@rm node*/run.sh run_cluster.sh teamocil.yml 2>/dev/null || true
	@echo ""
	@echo "Generating bootnode p2pkey"
	$(charon_cmd) gen-p2pkey --data-dir=/charon/bootnode 1>/dev/null

.PHONY: disable-simnet
disable-simnet:
	@echo "Disabling simnet by overwriting beaconode.env with beacon_node_endpoint=$(beacon_node_endpoint)"
	@if [ "$(beacon_node_endpoint)" == "" ]; then echo "Please provide beacon_node_endpoint variable: make beacon_node_endpoint=<value> disable-simnet" && exit 1; fi
	@if [ ! -f beaconnode.env.old ]; then mv beaconnode.env beaconnode.env.old; fi
	@echo "CHARON_BEACON_NODE_ENDPOINT=$(beacon_node_endpoint)" > beaconnode.env
