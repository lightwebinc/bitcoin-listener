# bitcoin-listener

Infrastructure automation for deploying
[`bitcoin-shard-listener`](https://github.com/lightwebinc/bitcoin-shard-listener)
nodes — the multicast-subscriber / unicast-forwarder counterpart to
[`bitcoin-ingress`](https://github.com/lightwebinc/bitcoin-ingress).

## What this repo provides

- **Ansible** roles and playbooks to build, install, and operate
  `bitcoin-shard-listener` on Ubuntu 24.04 and FreeBSD 14.
- **Terraform** modules and examples (cloud-agnostic + AWS EC2).
- **Default-on multicast-fabric firewall** (nftables / pf) enforcing the
  invariant that the fabric interface carries only multicast data inbound
  and NACK datagrams outbound.
- **BGP integration** (BIRD2 or FRR) for advertising listener
  reachability into the fabric.

## Quick start

```sh
# Ansible-only (existing hosts)
cd ansible
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.example.yml inventory/hosts.yml
$EDITOR inventory/hosts.yml
ansible-playbook -i inventory/hosts.yml site.yml

# Terraform (AWS EC2)
cd terraform/examples/aws-ec2
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
terraform init && terraform apply
```

## Documentation

- [Architecture](docs/architecture.md)
- [Ansible usage](docs/ansible.md)
- [Security (multicast-fabric perimeter)](docs/security.md)
- [BGP](docs/bgp.md)
- [Networking](docs/networking.md)
- [LXD lab guide](docs/lxd-lab.md)
- [Terraform](docs/terraform.md)
- OS notes: [Ubuntu 24.04](docs/os/ubuntu-24.04.md), [FreeBSD 14](docs/os/freebsd-14.md)

## Relationship to `bitcoin-ingress`

| Concern        | `bitcoin-ingress`      | `bitcoin-listener`                   |
|----------------|------------------------|---------------------------------------|
| Direction      | TX (send)              | RX (receive)                          |
| Listen / fwd   | UDP 9000 → mcast 9001  | mcast 9001 → UDP/TCP `egress_addr`    |
| Metrics port   | `:9100`                | `:9200`                               |
| Default AS     | `65001`                | `65002`                               |
| Firewall role  | n/a                    | built-in (default on)                 |

## License

MIT — see [LICENSE](LICENSE).
