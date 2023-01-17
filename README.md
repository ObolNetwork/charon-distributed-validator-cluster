![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Distributed Validator Cluster with Docker Compose</h1>

This repo contains a [charon](https://github.com/ObolNetwork/charon) distributed validator cluster which you can run using [docker-compose](https://docs.docker.com/compose/).

This repo aims to give users a feel for what a [Distributed Validator Cluster](https://docs.obol.tech/docs/int/key-concepts#distributed-validator-cluster) means in practice, and what the future of high-availability, fault-tolerant proof of stake validating deployments will look like.

A distributed validator cluster is a docker-compose file with the following containers running:

- Single [Nethermind](https://github.com/NethermindEth/nethermind) execution layer client
- Single [Lighthouse](https://github.com/sigp/lighthouse) consensus layer client
- Six [charon](https://github.com/ObolNetwork/charon) Distributed Validator clients
- Two [Lighthouse](https://github.com/sigp/lighthouse) Validator clients
- Two [Teku](https://github.com/ConsenSys/teku) Validator Clients
- Two [Vouch](https://github.com/attestantio/vouch) Validator Clients
- Prometheus, Grafana and Jaeger clients for monitoring this cluster.

![Distributed Validator Cluster](DVCluster.png)

In the future, this repo aims to contain compose files for every possible Execution, Beacon, and Validator client combinations that is possible with DVT.

## Quickstart

Ensure you have [docker](https://docs.docker.com/engine/install/) and [git](https://git-scm.com/downloads) installed. Also, make sure `docker` is running before executing the commands below.

1. Clone the [charon-distributed-validator-cluster](https://github.com/ObolNetwork/charon-distributed-validator-cluster) repo and `cd` into the directory.

   ```sh
   # Clone the repo
   git clone https://github.com/ObolNetwork/charon-distributed-validator-cluster.git

   # Change directory
   cd charon-distributed-validator-cluster/
   ```

1. Prepare the environment variables

   ```sh
   # Copy the sample environment variables
   cp .env.sample .env
   ```
   `.env.sample` is a sample environment file that allows overriding default configuration defined in `docker-compose.yml`. Uncomment and set any variable to override its value.

1. Create the artifacts needed to run a testnet distributed validator cluster

   ```sh
   # Create a testnet distributed validator cluster
   docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:v0.12.0 create cluster --withdrawal-address="0x000000000000000000000000000000000000dead" --nodes 6 --threshold 5
   ```

1. Start the cluster
   ```sh
   # Start the distributed validator cluster
   docker-compose up --build
   ```
1. Checkout the monitoring dashboard and see if things look all right

   ```sh
   # Open Grafana
   open http://localhost:3000/d/laEp8vupp
   ```

If all the above went correctly, it's natural to see logs like:

`INFO sched      No active DVs for slot {"slot": 3288627}`

This is because you need to activate your freshly created distributed validator on the testnet with the [existing launchpad](https://prater.launchpad.ethereum.org/en/). The validator deposit data should be in `.charon/cluster/deposit-data.json`.

## Distributed Validator Cluster

The default cluster consists of:
- [Nethermind](https://github.com/NethermindEth/nethermind), an execution layer client
- [Lighthouse](https://github.com/sigp/lighthouse), a consensus layer client
- Six [charon](https://github.com/ObolNetwork/charon) nodes
- Mixture of validator clients:
  - vc0: [Lighthouse](https://github.com/sigp/lighthouse)
  - vc1: [Teku](https://github.com/ConsenSys/teku)
  - vc2: [Vouch](https://github.com/attestantio/vouch)
  - vc3: [Lighthouse](https://github.com/sigp/lighthouse)
  - vc4: [Teku](https://github.com/ConsenSys/teku)
  - vc5: [Vouch](https://github.com/attestantio/vouch)

The intention is to support all validator clients, and work is underway to add support for lodestar to this repo, with [nimbus](https://github.com/ObolNetwork/charon-distributed-validator-cluster/issues/67) and [prysm](https://github.com/ObolNetwork/charon-distributed-validator-cluster/issues/68) support to follow in the future. Read more about our client support [here](https://github.com/ObolNetwork/charon#supported-consensus-layer-clients).

## Create Distributed Validator Keys

Create some testnet private keys for a six node distributed validator cluster with the command:

```sh
docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:v0.12.0 create cluster --withdrawal-address="0x000000000000000000000000000000000000dead" --nodes 6 --threshold 5
```

This command will create a subdirectory `.charon/cluster`. In it are six folders, one for each charon node created. Each folder contains partial private keys that together make up distributed validators defined in the `cluster-lock.json` file.


### Activate your validator

Along with the private keys and cluster lock file is a validator deposit data file located inside each node folder. For example, you can find the deposit data file inside the `node0` folder at
`.charon/cluster/node0/deposit-data.json`. You can use the original [staking launchpad](https://prater.launchpad.ethereum.org/) app to activate your new validator with the original UI.

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

# Put the validator `keystore.json` files in this folder.
# Alongside them, with a matching filename but ending with `.txt` should be the password to the keystore.
# E.g., keystore-0.json keystore-0.txt

# Split these keystores into "n" (--nodes) key shares with "t" (--threshold) as threshold for a distributed validator
docker run --rm -v $(pwd):/opt/charon obolnetwork/charon:v0.12.0 create cluster --split-existing-keys --split-keys-dir=/opt/charon/split_keys --threshold 4 --nodes 6

# The above command will create 6 validator key shares along with cluster-lock.json and deposit-data.json in ./.charon/cluster : 

***************** WARNING: Splitting keys **********************
 Please make sure any existing validator has been shut down for
 at least 2 finalised epochs before starting the charon cluster,
 otherwise slashing could occur.                               
****************************************************************

Created charon cluster:
 --split-existing-keys=true

.charon/cluster/
├─ node[0-5]/                   Directory for each node
│  ├─ charon-enr-private-key    Charon networking private key for node authentication
│  ├─ cluster-lock.json         Cluster lock defines the cluster lock file which is signed by all nodes
│  ├─ deposit-data.json         Deposit data file is used to activate a Distributed Validator on DV Launchpad
│  ├─ validator_keys            Validator keystores and password
│  │  ├─ keystore-*.json        Validator private share key for duty signing
│  │  ├─ keystore-*.txt         Keystore password files for keystore-*.json

```

## Project Status

It is still early days for the Obol Network and everything is under active development.
It is NOT ready for mainnet.
Keep checking in for updates, [here](https://github.com/ObolNetwork/charon/#supported-consensus-layer-clients) is the latest on charon's supported clients and duties.

> Remember: Please make sure any existing validator has been shut down for
> at least 3 finalised epochs before starting the charon cluster,
> otherwise your validator could be slashed.

## Integrating Vouch with charon cluster

[Vouch](https://github.com/attestantio/vouch) is a validator client (VC) for ethereum. The following outlines how we support vouch in a charon distributed validator cluster.

### Requirements
- The `vouch/` directory contains a basic vouch config file `vouch.yml` which is programmatically populated by `run.sh`.
- `Dockerfile` is used for building vouch image which uses `run.sh` as entrypoint.
- The `run.sh` script:
    - Creates an [ethdo](https://github.com/wealdtech/ethdo) wallet which imports the keystores created during dkg ceremony or with `charon create cluster` command.
    - Adds the `beacon-node-address` for vouch VC to use. This is obtained from `VOUCH_BEACON_NODE_ADDRESS` environment variable in `docker-compose.yml`.
    - Starts the validator client.

### Why is custom config required?
- Vouch requires a [configuration file](https://github.com/attestantio/vouch/blob/master/docs/configuration.md#the-configuration-file) called `vouch.yml` (or `vouch.json`). This config requires certain fields that are specific to running a instance of vouch.
- Timeout is set to 10s in `vouch.yml` for all the strategies supported to allow sufficient time for fetching duties for DVT.
- Since vouch supports wallets created by ethdo, `run.sh` script is needed to import the keystores and create a corresponding ethdo wallet.
- Creation of wallet is done programatically since each VC has different set of keystores.

# Troubleshooting

[Check the docs](https://docs.obol.tech/docs/int/faq/errors) for some common errors and how to fix them.
