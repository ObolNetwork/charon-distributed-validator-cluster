![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Charon in a Docker Compose</h1>

This repo contains a [charon](https://github.com/ObolNetwork/charon) distributed validator cluster running with docker-compose.

## Usage

Ensure you have [docker](https://docs.docker.com/engine/install/) and [git](https://git-scm.com/downloads) installed. Also, make sure `docker` is running before executing the commands below.

```sh
git clone git@github.com:ObolNetwork/charon-docker-compose.git
cd charon-docker-compose
make                                   # Shows available make targets
make clean                             # Deletes previously created cluster
make up
open http://localhost:3000/d/B2zGKKs7k # Open Grafana simnet dashboard
open http://localhost:16686            # Open Jaeger dashboard
```

## Mocked Beacon Node

By default this repo uses a `simulated network`, or `simnet`, which uses a mocked beacon node to avoid the complexities of depositing stake and waiting for validator activation.
It uses custom configuration for slots and epoch timing (1s per slot, 16 slots per epoch). It assigns attestation duties to the simnet 
distributed validator on the first slot of every epoch.

The default cluster consists of 4 charon nodes using a mixture of validator clients:
- node0: [Lighthouse](https://github.com/sigp/lighthouse)
- node1: [Teku](https://github.com/ConsenSys/teku)
- node2: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)
- node3: [mock validator client](https://github.com/ObolNetwork/charon/tree/main/testutil/validatormock)

## Creating Validator Keys

Create some testnet private keys and their associated data with the command:

```
docker run --rm -v "$(pwd)/.charon:/opt/charon" ghcr.io/obolnetwork/charon:v0.4.0 create cluster --cluster-dir="cluster"
```


### Creating keys with ethdo
In `charon v0.4.0`, local key creation and distributed key creation will be possible with the `charon create cluster` and `charon create dkg` commands. Until then, you can create keys with [ethdo](https://github.com/wealdtech/ethdo) and split them, like so:

```sh
# Create Ethdo Wallet in this directory
docker run -v "$(pwd)/.data:/data" wealdtech/ethdo:latest --basedir="/data" wallet create --wallet="test" 
--walletpassphrase="test"

# Create an account in this wallet
docker run -v "$(pwd)/.data:/data" wealdtech/ethdo:latest --basedir="/data" account create --walletpassphrase="test" --account="test/1" --passphrase="test"

# Verify the wallet looks right
docker run -v "$(pwd)/.data:/data" wealdtech/ethdo:latest --basedir="/data" wallet info --wallet="test" 

# Verify an account was created
docker run -v "$(pwd)/.data:/data" wealdtech/ethdo:latest --basedir="/data" account info --account="test/1" 

# Create a deposit data file
docker run -v "$(pwd)/.data:/data" wealdtech/ethdo:latest --basedir="/data" validator depositdata --validatoraccount="test/1" --withdrawalaccount="test/1" --depositvalue="32 ether" --forkversion="0x00001020" --passphrase="test" --raw

```

### Creating keys with the Staking-Deposit-CLI

You can also create keys with the [staking deposit CLI](https://github.com/ethereum/staking-deposit-cli#option-4-use-docker-image) by running the following commands:

```sh
# Checkout the repo
git clone https://github.com/ethereum/staking-deposit-cli
cd staking-deposit-cli

# Build the docker image
make build_docker

# Run the image
docker run -it --rm -v $(pwd)/split_keys:/app/validator_keys ethereum/staking-deposit-cli new-mnemonic --num_validators=1 --mnemonic_language=english --chain=prater
```

## Project Status

It is still early days for the Obol Network and everything is under active development. 
It is NOT ready for mainnet. 
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

## Makefile features

### `make clean`: Clean and reset cluster

`make clean` performs the following actions:
- Stops and removes all running containers, `docker-compose down` 
- Deletes created cluster artifacts


| ⚠️ The features below are only for the brave ⚔️ 🐉 |
|----------------------------------------------------|

### `make split-existing-keys`: Create a cluster by splitting existing non-dvt validator keys


Existing non-dvt validator keys stored in `./split_keys/` folder will be split into threshold BLS partial shares.

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
