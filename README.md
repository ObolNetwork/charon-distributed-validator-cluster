# Charon-docker-compose

Run a simnet [charon](https://github.com/ObolNetwork/charon) distributed validator cluster using docker-compose.

> Simnet is a simulation network demonstrating the features available in charon, using mocked beacon-client and mocked validator-client.

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
# See the logs for simulated duties.
```

Note that by default, when node0 starts, it generates a new simnet cluster (manifest and p2pkeys).
To continue with a previously generated cluster, set the `CLEAN=false` env var.
```sh
CLEAN=false docker-compose up
```

## Project Status

It is still early days for the Obol Network and everything is under active development. 
It is NOT ready for mainnet or testnet for that matter. 
Keep checking in for updates.

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
