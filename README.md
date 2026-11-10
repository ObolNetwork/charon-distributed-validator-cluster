![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Distributed Validator Cluster with Docker Compose</h1>

This repo contains a [charon](https://github.com/ObolNetwork/charon) distributed validator cluster which you can run using [docker-compose](https://docs.docker.com/compose/).

This repo aims to give users a feel for what a [Distributed Validator Cluster](https://docs.obol.tech/docs/int/key-concepts#distributed-validator-cluster) means in practice, and what the future of high-availability, fault-tolerant proof of stake validating deployments will look like.

**This repo runs on a single machine, with only one execution and consensus client, you do not have fault tolerance with this setup, and this is only for demonstration purposes only, and should not be used in a production context.**

A distributed validator cluster is a docker-compose file with the following containers running:

- Single [Nethermind](https://github.com/NethermindEth/nethermind) execution layer client
- Single [Lighthouse](https://github.com/sigp/lighthouse) consensus layer client
- Single [MEV-boost](https://github.com/flashbots/mev-boost) client, used by the consensus layer client as its builder
- Six [charon](https://github.com/ObolNetwork/charon) Distributed Validator clients
- One [Lighthouse](https://github.com/sigp/lighthouse) Validator client
- One [Teku](https://github.com/ConsenSys/teku) Validator client
- One [Nimbus](https://github.com/status-im/nimbus-eth2) Validator client
- One [Prysm](https://github.com/OffchainLabs/prysm) Validator client
- Two [Lodestar](https://github.com/ChainSafe/lodestar) Validator clients
- Prometheus and Grafana for monitoring this cluster.

![Distributed Validator Cluster](DVCluster.png)

In the future, this repo aims to contain compose files for every possible Execution, Beacon, and Validator client combinations that is possible with DVT.

## Quickstart

You can view a quickstart guide for testing this repo out on our [docs site](https://docs.obol.tech/docs/start/quickstart_alone).

## Configuration

Copy the `.env.sample.<NETWORK>` file for the network you want to run on to `.env`, where `<NETWORK>` is one of `hoodi`, `sepolia` or `mainnet`:

```sh
cp .env.sample.hoodi .env
```

`ETH2_NETWORK` is required and has no default. The sample files set it, along with the matching Lighthouse checkpoint sync URL. `PROM_REMOTE_WRITE_TOKEN` is also required, since Prometheus exits on start without it. Set `FEE_RECIPIENT` to the address that should receive priority fees and MEV rewards. Every other variable is optional and overrides a default in `docker-compose.yml`.

## Security

Grafana, Prometheus and the execution and beacon node APIs are only published on `127.0.0.1`. To view Grafana from another machine, use an SSH tunnel: `ssh -L 3000:127.0.0.1:3000 <user>@<host>`, then open `http://localhost:3000`. Anonymous visitors get read-only access. Docker-published ports bypass host firewalls such as `ufw`, so only publish them on other addresses if a provider or network firewall restricts who can reach them.

If you ran an earlier release with Grafana reachable from the internet, recreate its container to discard any changes made to it: `docker compose up -d --force-recreate grafana`.

The Engine API secret shared by the execution and consensus clients is unique to each deployment. On first start, the `jwt-init` service generates a random secret in the `jwt` Docker volume, which only the execution and consensus clients mount, so it is not a file in this directory.

- **Upgrading:** older releases shipped the same `jwt/jwt.hex` to every operator. After `git pull`, the next `docker compose up -d` recreates the execution and consensus clients with a new secret, and nothing else is needed. Start them together: a client still running from before the update cannot authenticate to one that has the new secret.
- **If `git pull` stops because you changed `jwt/jwt.hex`,** run `git checkout jwt/jwt.hex` and pull again.
- **To use your own secret,** for example with an execution client outside this stack, put it in `jwt/jwt.hex` as 64 hex characters (copy it aside before the `git checkout`), then run `docker compose up -d --force-recreate`. The secret that older releases shipped is ignored.
- **To print the secret in use:** `docker compose run --rm jwt-init cat /jwt/jwt.hex`.

## Project Status

See [dvt.obol.tech](https://dvt.obol.tech/) for the latest status of the Obol Network including which upstream consensus clients and which downstream validators are supported.

> Remember: Please make sure any existing validator has been shut down for
> at least 3 finalised epochs before starting the charon cluster,
> otherwise your validator could be slashed.

# Troubleshooting

[Check the docs](https://docs.obol.tech/docs/faq/errors) for some common errors and how to fix them.
