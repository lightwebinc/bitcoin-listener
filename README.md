# shard-listener

[![Lint](https://github.com/lightwebinc/listener-infra/actions/workflows/lint.yml/badge.svg)](https://github.com/lightwebinc/listener-infra/actions/workflows/lint.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> Part of the [**BSV Layered Multicast**](https://github.com/lightwebinc/bsv-multicast) open-source project — see the main repository for the full architecture, design docs, and BRC specifications.

Ansible and Terraform automation for deploying
[`shard-listener`](https://github.com/lightwebinc/shard-listener)
nodes — multicast subscribers that filter and forward BSV transactions to
downstream consumers.

```text
FF05::<shard>:9001  ──multicast──▶  shard-listener  ──UDP/TCP──▶  consumer
                                    (this repo deploys)
```

Includes a default-on multicast-fabric firewall (nftables / pf) and optional
BGP integration (BIRD2 / FRR) for listener reachability.

## Supported Platforms

| OS           | Automation | Service Manager |
| ------------ | ---------- | --------------- |
| Ubuntu 24.04 | Ansible    | systemd         |
| FreeBSD 14   | Ansible    | rc.d            |
| AWS EC2      | Terraform  | systemd         |
| Any SSH host | Terraform  | generic         |

## Quick Start

```sh
cd ansible
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.example.yml inventory/hosts.yml
$EDITOR inventory/hosts.yml
ansible-playbook -i inventory/hosts.yml site.yml
```

## Documentation

- [Architecture](docs/architecture.md)
- [Ansible usage](docs/ansible.md)
- [Security (fabric perimeter)](docs/security.md)
- [BGP](docs/bgp.md)
- [Networking](docs/networking.md)
- [Terraform](docs/terraform.md)
- OS notes: [Ubuntu 24.04](docs/os/ubuntu-24.04.md), [FreeBSD 14](docs/os/freebsd-14.md)

## Repository Layout

```text
ansible/     Roles and playbooks
terraform/   Modules and cloud examples
docs/        Per-topic documentation
```

## License

Apache 2.0 — see [LICENSE](LICENSE).
