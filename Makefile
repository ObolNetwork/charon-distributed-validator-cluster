# Use locally built charon if present
entrypoint := $(if $(wildcard charon),/charon-docker-compose/charon,/usr/local/bin/charon)

# Pegged charon version (update this for each release).
version := v0.3.0

charon_cmd := docker run --rm --entrypoint=$(entrypoint) -v $(shell pwd):/charon-docker-compose ghcr.io/obolnetwork/charon:$(version)

# Default cluster. Override example: make t=4 n=5 create-cluster
n := 4
t := 3

# Default split keys dir (must be subdirectory of this repo).
split_keys_dir := split_keys

.DEFAULT_GOAL := help
.PHONY: help
help:
	@echo "The following *make* targets are available:"
	@echo " up               Create and start docker-compose containers"
	@echo " down             Stop and remove docker-compose resources"
	@echo " create-cluster   Creates a simnet cluster"
	@echo " build-local      Build local charon binary from source (instead of using binary in container)"
	@echo " clean            Cleans previously created cluster"
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
	@echo "Pulling latest container" && docker pull ghcr.io/obolnetwork/charon:latest 1>/dev/null

.PHONY: build-local
build-local:
	@./build_local.sh

.PHONY: create-cluster
create-cluster:
	@echo "Creating simnet cluster"
	$(charon_cmd) create-cluster -t=$(t) -n=$(n) --cluster-dir=/charon-docker-compose

.PHONY: split-existing-keys
split-existing-keys:
	@if [ ! -f $(split_keys_dir)/keystore*.json ]; then echo "No keys in $(split_keys_dir)/ directory" && exit 1; fi
	@echo "Creating cluster by splitting existing validator keys"
	$(charon_cmd) create-cluster --split-existing-keys --split-keys-dir=/charon-docker-compose/$(split_keys_dir) -t=$(t) -n=$(n) --cluster-dir=/charon-docker-compose

.PHONY: disable-simnet
disable-simnet:
	@echo "Disabling simnet by overwriting beaconode.env with beacon_node_endpoint=$(beacon_node_endpoint)"
	@if [ "$(beacon_node_endpoint)" == "" ]; then echo "Please provide beacon_node_endpoint variable: make beacon_node_endpoint=<value> disable-simnet" && exit 1; fi
	@if [ ! -f beaconnode.env.old ]; then mv beaconnode.env beaconnode.env.old; fi
	@echo "CHARON_BEACON_NODE_ENDPOINT=$(beacon_node_endpoint)" > beaconnode.env
