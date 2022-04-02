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
make                                   # Shows available make targets
make clean                             # Deletes previously generated cluster
make gen-cluster                       # Generates simnet cluster
docker-compose up
open http://localhost:3000/d/B2zGKKs7k # Open Grafana simnet dashboard
open http://localhost:16686            # Open Jaeger dashboard
```

## Mocked Beacon Node

The simnet uses a mocked beacon node to avoid the complexities of depositing stake and waiting for validator activation.
It uses custom configuration for slots and epoch timing (1s per slot, 16 slots per epoch). It assigns attestation duties to the simnet 
distributed validator on the first slot of every epoch.

The default cluster consists of 4 charon nodes uses a mixture of validator clients:
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

## Makefile features

### `make clean`: Clean and reset cluster

`make clean` performs the following actions:
- Stops and removes all running containers, `docker-compose down` 
- Deletes generated cluster artifacts
- Enables simnet (if previously disabled)
- Pulls latest container.
- Deletes locally built binary if present

### `make gen-cluster`: Generate simnet cluster

Generates a simnet cluster with 4 nodes (n=4) and threshold of 3 (t=3) for signature reconstruction.

```
# Override n and/or t
make n=5 t=4 gen-cluster
```

### `make build-local`: Running locally built charon binary 

Testing and debugging charon-docker-compose by running a locally built charon binary in the containers is supported: 
```sh
# Checkout charon repo next to charon-docker-compose
cd ..
git clone git@github.com:ObolNetwork/charon.git

# If charon repo is in a different path.
# export CHARON_REPO=<path to charon repo>  

make build-local
docker-compose up
```

>  **WARNING**: The features below are only for the brave who know what they are doing ⚔️ 🐉

### `make disable-simnet`: Disable simnet mock beacon node

Disables the simnet mock beacon node and configures a real beacon node endpoint.

```
make beacon_node_endpoint=<url> disable-simnet
```


> Remember: Do not connect to main net! 

### `make split-existing-keys`: Create a cluster by splitting existing non-dvt validator keys

This uses the same command as `gen-cluster` command but doesn't create new random keys. 
Rather existing non-dvt validator keys stored in `./split_keys/` folder are split into threshold BLS partial shares.

```
mkdir split_keys
cp path/to/existing/keys/keystore-*.json split_keys/
cp path/to/passwords/keystore-*.txt split_keys/
# Each keystore-*.json requires a keystore-*.txt file containing the password.
make split-existing-keys
make up
```

> Remember: Please make sure any existing validator has been shut down for
> at least 2 finalised epochs before starting the charon cluster,
> otherwise slashing could occur.
