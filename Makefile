# Pull charon version from env file
include .env
export
charon_version := ${CHARON_VERSION}
charon_cmd := docker run --rm  -v $(shell pwd):/opt/charon ghcr.io/obolnetwork/charon:$(charon_version)

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
	@echo " clean            Cleans previously created cluster"
	@echo ""
	@echo "Targets only for the brave ⚔️ 🐉:"
	@echo " split-existing-keys    Create a cluster by splitting existing non-dvt validator keys"

.PHONY: up
up:
	if [ ! -f ".charon/cluster/manifest.json" ]; then echo "Cluster not created yet. Create a test one with `charon create cluster`." && exit 1; fi
	docker-compose up --build

.PHONY: down
down:
	docker-compose down

.PHONY: clean
clean:
	@echo "docker-compose down" && docker-compose down 1>/dev/null
	@echo "Cleaning cluster manifest, node config and node keys"
	@rm -rf .charon 2>/dev/null || true
	@rm -f bootnode/* 2>/dev/null || true
	@rm -rf lighthouse/*/ 2>/dev/null || true
	@[ -f charon ] && echo "Deleting locally built charon binary" || true
	@rm charon 2>/dev/null || true

.PHONY: split-existing-keys
split-existing-keys:
	@if [ ! -f $(split_keys_dir)/keystore*.json ]; then echo "No keys in $(split_keys_dir)/ directory" && exit 1; fi
	@echo "Creating cluster by splitting existing validator keys"
	$(charon_cmd) create-cluster --split-existing-keys --split-keys-dir=/opt/charon/$(split_keys_dir) -t=$(t) -n=$(n) --cluster-dir=".charon/cluster"


.PHONY: create
create: 
	$(charon_cmd) create cluster --cluster-dir=".charon/cluster"
