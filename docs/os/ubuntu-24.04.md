# Ubuntu 24.04 (Noble)

## Service management

```sh
systemctl status bitcoin-shard-listener
systemctl restart bitcoin-shard-listener
journalctl -u bitcoin-shard-listener -f

# BGP health-check timer (when enable_bgp: true)
systemctl status bsl-bgp-check.timer
journalctl -u bsl-bgp-check.service --since -5min
```

Unit file: `/etc/systemd/system/bitcoin-shard-listener.service`
(see template
`@/home/light/repo/bitcoin-listener/ansible/roles/bitcoin-shard-listener/templates/bitcoin-shard-listener.service.j2`).

Environment file: `/etc/bitcoin-shard-listener/config.env`.

## Network configuration

Netplan:

- `/etc/netplan/60-bitcoin-listener.yaml` — ingress ethernet
- `/etc/netplan/61-bitcoin-listener-gre.yaml` — GRE6 tunnel (when
  `ingress_mode: gre`)
- `/etc/netplan/62-bitcoin-listener-vip.yaml` — BGP VIP on loopback

Apply:

```sh
netplan apply
```

Sysctl: `/etc/sysctl.d/60-bitcoin-listener.conf`.

## Firewall

nftables ruleset: `/etc/nftables.d/60-bitcoin-listener.nft` (included from
`/etc/nftables.conf`).

```sh
nft list table inet bitcoin-listener
systemctl status nftables
```

## Package installation

The `common` role installs:

- `acl`, `build-essential`, `git`, `curl`, `ca-certificates`, `tar`
- `nftables` (when `enable_firewall: true`)
- `bird2` **or** `frr` (when `enable_bgp: true`)

The Go toolchain is installed to `/usr/local/go` (version configured via
`go_version`).

## BGP daemon paths

| Daemon | Config                       | Reload                            |
|--------|------------------------------|-----------------------------------|
| BIRD2  | `/etc/bird/bird.conf`        | `systemctl reload bird` / `birdc configure` |
| FRR    | `/etc/frr/frr.conf`          | `systemctl reload frr`            |

## Multicast diagnostics

```sh
# Joined groups
ip -6 maddr show dev eth0

# Live receive capture
tcpdump -i eth0 -nn 'udp and ip6 multicast and port 9001'

# Sysctl state
sysctl net.ipv6.conf.eth0.accept_ra
```

## Known issues

- **`ingress_iface` precedence.** Must be set per-host, not on group_vars.
- **LXD `acl` missing.** Installed by `common` role.
- **`git` "dubious ownership".** Handled by setting `safe.directory`.
