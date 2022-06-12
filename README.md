![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Distributed Validator Cluster with Docker Compose</h1>

This repo contains a [charon](https://github.com/ObolNetwork/charon) distributed validator cluster running using [docker-compose](https://docs.docker.com/compose/).

This repo aims to give users a feel for what a [Distributed Validator Cluster](https://docs.obol.tech/docs/int/key-concepts#distributed-validator-cluster) means in practice, and what the future of high-availability, fault-tolerant proof of stake validating deployments will look like.

## Quickstart

Ensure you have [docker](https://docs.docker.com/engine/install/) and [git](https://git-scm.com/downloads) installed. Also, make sure `docker` is running before executing the commands below.

```sh
# Clone this repo
git clone git@github.com:ObolNetwork/charon-docker-compose.git

# Change directory
cd charon-docker-compose

# Prepare an environment variable file (requires at minimum an Infura API endpoint for your chosen chain)
cp .env.sample .env

# Shows available make targets
make

# Deletes previously created cluster
make clean

# Create the artifacts for a new test cluster
make create

# Start the cluster
make up

# Open Grafana dashboard
open http://localhost:3000/d/laEp8vupp

# Open Jaeger dashboard
open http://localhost:16686
```

If all the above went correctly, you can activate your validator on the testnet with the [existing launchpad](https://prater.launchpad.ethereum.org/en/). The validator deposit data should be in `.charon/deposit-data.json`.

## Remote Beacon Node

This repo assumes the use of a remote Ethereum Consensus Layer API, offered through a product like [Infura](https://infura.io/).

This only makes sense for a demo validator, and should not be done in a production scenarion. Similarly, a remote beacon node drastically impacts the latency of the system, and is likely to produce sub par validator inclusion distance relative to one with a local consensus client.

The default cluster consists of 4 charon nodes using a mixture of validator clients:

- vc0: [Lighthouse](https://github.com/sigp/lighthouse)
- vc1: [Teku](https://github.com/ConsenSys/teku)
- vc2: [Teku](https://github.com/ConsenSys/teku)
- vc3: [Teku](https://github.com/ConsenSys/teku)

The intention is to support all validator clients, and work is underway to add support for vouch and lodestar to this repo, with nimbus and prysm support to follow in future. Read more about our client support [here](https://github.com/ObolNetwork/charon#supported-consensus-layer-clients).

## Creating Test Distributed Validator Private Keys

Create some testnet private keys for a 4 node distributed validator cluster with the command:

```sh
docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:latest create cluster --cluster-dir=".charon" --withdrawal-address="0x000000000000000000000000000000000000dead"
```

You can also run `make create` if you prefer to use [Make](https://www.gnu.org/software/make/).

This command will create a subdirectory `.charon`. In it are four folders, each with different private keys that together make up the distributed validator described in `.charon/cluster-lock.json`

### Activating your validator

Along with the private keys and cluster lock file is a validator deposit data file located at `.charon/deposit-data.json`. You can use the original [staking launchpad](https://prater.launchpad.ethereum.org/) app to activate your new validator with the original UI.

Your deposit will take at minimum 8 hours to process, near to the time you can run this new cluster with the command:

```
docker-compose up --build
```

## Import Existing Validator Keys

You might already have keys to an active validator, or are more comfortable creating keys with existing tooling like the [staking deposit CLI](https://github.com/ethereum/staking-deposit-cli) and [ethdo](https://github.com/wealdtech/ethdo).

To import existing EIP-2335 validator key stores:

```sh
# Create a folder within this checked out repo
mkdir split_keys

# Put the validator keystore.json files in this folder.
# Alongside them, with a matching filename but ending with `.txt` should be the password to the keystore.
# E.g. keystore-0.json keystore-0.txt

# Split these keystores into key shares for a distributed validator
make split-existing-keys
```

## Project Status

It is still early days for the Obol Network and everything is under active development.
It is NOT ready for mainnet.
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

## Makefile features

### `make create`: Create required artifacts for a testnet cluster

`make create` performs the following actions:

- Call `charon create cluster` to produce ENRs, cluster lock files, distributed validator private keys, and deposit and exit data for the created validator.
- These artifacts are only suitable for test uses cases and should not be distributed to others. Clusters with groups of operators should perform a DKG ceremony using `charon dkg`.

### `make clean`: Clean and reset cluster

`make clean` performs the following actions:

- Stops and removes all running containers, `docker-compose down`
- Deletes created cluster artifacts

| ⚠️ The features below are only for the brave ⚔️ 🐉 |
| -------------------------------------------------- |

### `make split-existing-keys`: Create a cluster by splitting existing validator private keys

Existing validator keys stored in `./split_keys/` folder can be split into threshold private keys suitable for operating in a distributed validator.

```sh
# Create the folder that holds the original keystores
mkdir split_keys

# Copy in the keystores
cp path/to/existing/keys/keystore-*.json split_keys/

# Copy in the password files
cp path/to/passwords/keystore-*.txt split_keys/

# Each keystore-*.json requires a keystore-*.txt file containing the password.
make split-existing-keys

# Bring up the cluster
make up
```

> Remember: Please make sure any existing validator has been shut down for
> at least 3 finalised epochs before starting the charon cluster,
> otherwise your validator could be slashed.

# Troubleshooting

Here are some common errors and how to decipher how to fix them:

## Beacon Nodes

## Charon Nodes


-   ```
    Fatal run error: read lock: open .charon/cluster-lock.json: permission denied
    Error: read lock: open .charon/cluster-lock.json: permission denied
    ```
    This error was received when I called `charon create cluster` on a local dev machine, and then copied and pasted the generated files in `.charon` to my remote eth2 server. The fix was to run `sudo chmod -R o+r .charon/`

## Validator Clients

### Teku

```
Keystore file /opt/charon/keys/keystore-0.json.lock already in use.
```

This can happen when you recreate a docker cluster with the same cluster files. Delete all `.charon/node<teku-vc-index-here>/keystore-*.json.lock` files to fix this.

```
java.util.concurrent.CompletionException: java.lang.RuntimeException: Unexpected response from Beacon Node API (url = http://node1:16002/eth/v1/beacon/states/head/validators?id=0x8c4758687121c3b35203c69925e8056799369e0dac2c31c9984946436f3041821080a58e6c1a813b4de1007333552347, status = 404)
```

This indicates your validator is probably not activated yet.

### Lighthouse

```
May 20 12:48:43.046 WARN Unable to connect to a beacon node      available: 0, total: 1, retry in: 2 seconds
May 20 12:48:45.048 WARN Offline beacon node                     endpoint: http://node0:16002/, error: Reqwest(reqwest::Error { kind: Request, url: Url { scheme: "http", cannot_be_a_base: false, username: "", password: None, host: Some(Domain("node0")), port: Some(16002), path: "/eth/v1/node/version", query: None, fragment: None }, source: hyper::Error(Connect, ConnectError("dns error", Custom { kind: Uncategorized, error: "failed to lookup address information: Temporary failure in name resolution" })) })
```

The above error was caused when the upstream charon client for this validator had died and not restarted.