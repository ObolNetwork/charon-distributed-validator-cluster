![Obol Logo](https://obol.tech/obolnetwork.png)

<h1 align="center">Distributed Validator Cluster with Docker Compose</h1>

This repo contains a [charon](https://github.com/ObolNetwork/charon) distributed validator cluster which you can run using [docker-compose](https://docs.docker.com/compose/).

This repo aims to give users a feel for what a [Distributed Validator Cluster](https://docs.obol.tech/docs/int/key-concepts#distributed-validator-cluster) means in practice, and what the future of high-availability, fault-tolerant proof of stake validating deployments will look like.

**This repo runs on a single machine, with only one execution and consensus client, you do not have fault tolerance with this setup, and this is only for demonstration purposes only, and should not be used in a production context.**

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

You can view a quickstart guide for testing this repo out on our [docs site](https://docs.obol.tech/docs/next/int/quickstart/alone/test-locally).

## Project Status

See [dvt.obol.tech](https://dvt.obol.tech/) for the latest status of the Obol Network including which upstream consensus clients and which downstream validators are supported.

> Remember: Please make sure any existing validator has been shut down for
> at least 3 finalised epochs before starting the charon cluster,
> otherwise your validator could be slashed.

# Troubleshooting

[Check the docs](https://docs.obol.tech/docs/int/faq/errors) for some common errors and how to fix them.
