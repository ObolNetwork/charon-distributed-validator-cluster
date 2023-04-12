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
- Two [Nimbus](https://github.com/status-im/nimbus-eth2) Validator Clients
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
   # Define the number of validators
   NUM_VALS=1
   # Define withdrawal and fee recipient addresses for each validator (comma separated)
   WITHDRAWAL_ADDRS=0x000000000000000000000000000000000000dead
   FEE_RECIPIENT_ADDRS=0x000000000000000000000000000000000000dead
   docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:v0.15.0 create cluster --withdrawal-addresses="$WITHDRAWAL_ADDRS" --fee-recipient-addresses "$FEE_RECIPIENT_ADDRS" --name testnetdv --nodes 6 --threshold 5 -numvals=$NUM_VALS
   ```

1. Start the cluster
   ```sh
   # Start the distributed validator cluster
   docker compose up --build
   ```
1. Checkout the monitoring dashboard and see if things look all right

   ```sh
   # Open Grafana
   open http://localhost:3000/d/laEp8vupp
   ```

If everything goes correctly, it's natural to see logs like:

`INFO sched      No active DVs for slot {"slot": 3288627}`

This is because you need to activate your freshly created distributed validator on the testnet with the [existing launchpad](https://prater.launchpad.ethereum.org/en/). The validator deposit data should be
present inside each `node` directory, for example, `.charon/cluster/node0/deposit-data.json`.

## Distributed Validator Cluster

The default cluster consists of:
- [Nethermind](https://github.com/NethermindEth/nethermind), an execution layer client
- [Lighthouse](https://github.com/sigp/lighthouse), a consensus layer client
- Six [charon](https://github.com/ObolNetwork/charon) nodes
- Mixture of validator clients:
  - vc0: [Lighthouse](https://github.com/sigp/lighthouse)
  - vc1: [Teku](https://github.com/ConsenSys/teku)
  - vc2: [Nimbus](https://github.com/status-im/nimbus-eth2)
  - vc3: [Lighthouse](https://github.com/sigp/lighthouse)
  - vc4: [Teku](https://github.com/ConsenSys/teku)
  - vc5: [Nimbus](https://github.com/status-im/nimbus-eth2)

The intention is to support all validator clients, and work is underway to add support for lodestar to this repo, with [prysm](https://github.com/ObolNetwork/charon-distributed-validator-cluster/issues/68) support to follow
in the future. Read more about our client support [here](https://github.com/ObolNetwork/charon#supported-consensus-layer-clients).

## Create Distributed Validator Keys

Create some testnet private keys for a six node distributed validator cluster with the command:

```sh
# Define withdrawal and fee recipient addresses for each validator (comma separated)
WITHDRAWAL_ADDRS=0x000000000000000000000000000000000000dead
FEE_RECIPIENT_ADDRS=0x000000000000000000000000000000000000dead
docker run --rm -v "$(pwd):/opt/charon" ghcr.io/obolnetwork/charon:v0.15.0 create cluster --withdrawal-addresses="$WITHDRAWAL_ADDRS" --fee-recipient-addresses "$FEE_RECIPIENT_ADDRS" --name testnetdv  --nodes 6 --threshold 5
```

This command will create a subdirectory `.charon/cluster`. In it are six folders, one for each charon node created. Each folder contains partial private keys that together make up distributed validators defined in the `cluster-lock.json` file.


### Activate your validator

Along with the private keys and cluster lock file is a validator deposit data file located inside each node folder. For example, you can find the deposit data file inside the `node0` folder at
`.charon/cluster/node0/deposit-data.json`. You can use the original [staking launchpad](https://goerli.launchpad.ethereum.org/) app to activate your new validator with the original UI.

Your deposit will take at minimum 8 hours to process, near to the time you can run this new cluster with the command:

```
docker compose up --build
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

# Define withdrawal and fee recipient addresses for each validator (comma separated)
WITHDRAWAL_ADDRS=0x000000000000000000000000000000000000dead
FEE_RECIPIENT_ADDRS=0x000000000000000000000000000000000000dead

# Split these keystores into "n" (--nodes) key shares with "t" (--threshold) as threshold for a distributed validator
docker run --rm -v $(pwd):/opt/charon obolnetwork/charon:v0.15.0 create cluster --withdrawal-addresses="$WITHDRAWAL_ADDRS" --fee-recipient-addresses "$FEE_RECIPIENT_ADDRS" --name testnetdv --split-existing-keys --split-keys-dir=/opt/charon/split_keys --threshold 4 --nodes 6

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

## Run prysm VCs in a Distributed Validator Cluster

This section of the readme is intended for the "docker power users", i.e., for the ones who are familiar with working with docker-compose and want to have more flexibility and power to change the default configuration.

We use the "Multiple Compose File" feature which provides a very powerful way to override any configuration in docker-compose.yml without needing to modify git-checked-in files since that results in conflicts when upgrading this repo. See [this](https://docs.docker.com/compose/extends/#multiple-compose-files) for more details.

There are some additional compose files in this repository, compose-prysm.yml and docker-compose.override.yml.sample, along with the default docker-compose.yml file that you can use for this purpose.

We have provided experimental support of prysm validator client through `compose-prysm.yml` which needs a prysm beacon node to work alongside a REST based beacon node. Here are the steps to test prysm in a Distributed Validator Cluster:

1. Run the following command:
   ```sh
   cp docker-compose.override.yml.sample docker-compose.override.yml
   ```
2. **Disable** the VCs in `docker-compose.override.yml` that are to be replaced by corresponding prysm VCs by un-commenting profiles field ([more details on profiles](https://docs.docker.com/compose/profiles/)). Also disable the prysm VCs that are not required in the cluster in `docker-compose.override.yml`.
3. Run the following command:
   ```sh
   docker compose -f docker-compose.yml -f compose-prysm.yml -f docker-compose.override.yml up --build
   ```

Note: Support for prysm VCs with is in experimental phase as prysm doesn't provide complete support of REST API compatible validator client.

# Troubleshooting

[Check the docs](https://docs.obol.tech/docs/int/faq/errors) for some common errors and how to fix them.
