# Vouch

[Vouch](https://github.com/attestantio/vouch) is a validator client (VC) for ethereum. The following outlines how we support vouch in a charon distributed validator cluster.

## Requirements
- The `vouch/` directory contains a basic vouch config file `vouch.yml` which is programmatically populated by `run.sh`.
- `Dockerfile` is used for building vouch image which uses `run.sh` as entrypoint.
- The `run.sh` script:
    - Creates an [ethdo](https://github.com/wealdtech/ethdo) wallet which imports the keystores created during dkg ceremony or with `charon create cluster` command.
    - Adds the `beacon-node-address` for vouch VC to use. This is obtained from `VOUCH_BEACON_NODE_ADDRESS` environment variable in `docker-compose.yml`.
    - Starts the validator client.

## Why is custom config required?
- Vouch requires a [configuration file](https://github.com/attestantio/vouch/blob/master/docs/configuration.md#the-configuration-file) called `vouch.yml` (or `vouch.json`). This config requires certain fields that are specific to running a instance of vouch.
- For ex, it requires a top-level `beacon-node-address` field which is different for different charon node. Ex: http://node0:3600 for node0, http://node1:3600 for node1 etc.
- Timeout is set to 10s in `vouch.yml` for all the strategies supported to allow fetching duties for DVT.
- Since vouch supports wallets created by ethdo, run.sh script is needed to import the keystores and create a corresponding ethdo wallet. It also adds accountmanager configuration needed to add wallet to vouch.ynl.
- Creation of wallet is done programatically since each VC has different set of keystores.
