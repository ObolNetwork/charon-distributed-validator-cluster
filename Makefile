# Use locally built charon if present
entrypoint := $(if $(wildcard charon),/charon/charon,/usr/local/bin/charon)

# TODO(corverr): Replace with static version 0.3.0
charon_cmd := docker run --rm --entrypoint=$(entrypoint) -v $(shell pwd):/charon ghcr.io/obolnetwork/charon/charon:latest

.DEFAULT_GOAL := help
.PHONY: help
help:
	@echo $(charon_repo)
	@echo "The following make targets are available:"
	@echo " up           : Create and start docker-compose containers"
	@echo " down         : Stop and remove docker-compose resources"
	@echo " gen-cluster  : Generates a simnet cluster"
	@echo " build-local  : Build local charon binary from source (instead of using official docker binary)"
	@echo " clean        : Cleans previously generated cluster"

.PHONY: up
up:
	if [ ! -f "manifest.json" ]; then echo "Cluster not created yet" && exit 1; fi
	docker-compose up

.PHONY: down
down:
	docker-compose down

.PHONY: gen-cluster
gen-cluster:
	@echo "Generating simnet cluster (may take a moment...)"
	$(charon_cmd) gen-cluster --clean=false --simnet -t=3 -n=4 --cluster-dir=/charon 1>/dev/null
	@rm node*/run.sh run_cluster.sh teamocil.yml || true
	@echo ""
	@echo "Generating bootnode p2pkey"
	$(charon_cmd) gen-p2pkey --data-dir=/charon/bootnode 1>/dev/null

.PHONY: clean
clean:
	@echo "Cleaning cluster manifest, node config and node keys"
	@rm -f manifest.json 2>/dev/null || true
	@rm -f node*/* 2>/dev/null || true
	@rm -f bootnode/* 2>/dev/null || true
	@rm -rf lighthouse/*/ 2>/dev/null || true
	@[ -f charon ] && echo "Deleting locally built charon binary" || true
	@rm charon 2>/dev/null || true
	@rm .env 2>/dev/null || true

.PHONY: build-local
build-local:
	@./build_local.sh
