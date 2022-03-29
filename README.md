# Charon-docker-compose

Run a *simnet* [charon](https://github.com/ObolNetwork/charon) distributed validator cluster using docker-compose.

> Simnet is a simulation network demonstrating the features available in charon. It uses a mocked beacon-node  
> and a mixture of mock and real (Lighthouse and Teku) validator clients.

## Usage
[Authenticate](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry) to the container registry (`ghcr.io`) using a Personal Access Token:

```sh
export CR_PAT=YOUR_GITHUB_TOKEN
echo $CR_PAT | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```
Ensure you have [docker](https://docs.docker.com/engine/install/) and [git](https://git-scm.com/downloads) installed.

```sh
git clone git@github.com:ObolNetwork/charon-docker-compose.git
cd charon-docker-compose
docker-compose up
open http://localhost:3000/d/B2zGKKs7k # Open Grafana simnet dashboard
open http://localhost:16686            # Open Jaeger dashboard
```

Note that by default, when `node0` starts, it generates a new simnet cluster.
It does so by calling the `charon gen-simnet` command that generates files for a new charon cluster: `manifest.json` (cluster definition), 
`keystore-*.json` (BLS threshold private key shares) and `p2pkey` (networking) . 
Generating the keystore files is slow and takes up to 1 minute.
To continue with a previously generated cluster, set the `CLEAN=false` env var.
```sh
CLEAN=false docker-compose up
```

## Mocked Beacon Node

The simnet uses a mocked beacon node to avoid the complexities of depositing stake and waiting for validator activation.
It uses custom configuration for slots and epoch timing (1s per slot, 16 slots per epoch). It assigns attestation duties to the simnet 
distributed validator on the first slot of every epoch.

The cluster of 4 charon nodes uses a mixture of validator clients:
- node0: [Lighthouse](https://github.com/sigp/lighthouse)
- node1: [Teku](https://github.com/ConsenSys/teku)
- node2: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node3: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)

## Project Status

It is still early days for the Obol Network and everything is under active development. 
It is NOT ready for mainnet or testnet for that matter. 
Keep checking in for updates.

> Charon only support attestation duties at this point, so validator client errors relating to 
> other duties than attestation is expected (including attestation aggregation). 

## Running locally built charon binary 

Testing and debugging charon-docker-compose by running a locally built charon binary in the containers is supported: 
```sh
# Checkout charon repo next to charon-docker-compose
cd ..
git clone git@github.com:ObolNetwork/charon.git

# If charon repo is in a different path.
# export CHARON_REPO=<path to charon repo>  

./build_local.sh
docker-compose up
```
