# FreeBSD 14

## Service management

```sh
service bitcoin_shard_listener status
service bitcoin_shard_listener restart
tail -f /var/log/bitcoin_shard_listener.log
```

rc.d script: `/usr/local/etc/rc.d/bitcoin_shard_listener`
(see template
`@/home/light/repo/bitcoin-listener/ansible/roles/bitcoin-shard-listener/templates/bitcoin_shard_listener.rc.j2`).

Environment file: `/usr/local/etc/bitcoin-shard-listener.conf`.

Enable at boot:

```sh
sysrc bitcoin_shard_listener_enable=YES
```

## Network configuration

`/etc/rc.conf` entries managed by the `networking` role:

- `ifconfig_<iface>`, `ifconfig_<iface>_ipv6` (ethernet ingress)
- `cloned_interfaces="gif0"` + `ifconfig_gif0*` (GRE mode)
- `ifconfig_lo0_alias0` / `alias1` (BGP VIP)
- `ipv6_route_bsl_mcast` (multicast route on ingress iface)

Apply:

```sh
service netif restart
service routing restart
```

## Firewall (pf)

Anchor file: `/etc/pf.anchors/bitcoin-listener`, loaded from `/etc/pf.conf`
via a managed anchor block.

```sh
pfctl -sr
pfctl -a bitcoin-listener -sr
pfctl -f /etc/pf.conf
```

Enable:

```sh
sysrc pf_enable=YES pflog_enable=YES
service pf start
```

## Packages

The `common` role installs via `pkg`:

- `gmake`, `git`, `curl`, `ca_root_nss`, `bash`, `tar`
- `bird2` or `frr` (when `enable_bgp: true`)

Go toolchain: `/usr/local/go` (via tarball download).

## BGP daemon paths

| Daemon | Config                                | Reload                     |
|--------|---------------------------------------|----------------------------|
| BIRD2  | `/usr/local/etc/bird/bird.conf`       | `service bird reload`      |
| FRR    | `/usr/local/etc/frr/frr.conf`         | `service frr reload`       |

Health check runs via cron (every minute):
`/usr/local/bin/bsl-bgp-check.sh`.

## Multicast diagnostics

```sh
# Joined groups
netstat -g -f inet6

# Live capture
tcpdump -i vtnet0 -nn 'udp and ip6 multicast and port 9001'
```

## Known issues

- **Interface naming.** FreeBSD uses `vtnet0` / `em0` — set `ingress_iface`
  per-host accordingly.
- **`gif` interface name** is hard-coded in the rc.conf template to `gif0`.
  If multiple tunnels are needed, adapt the template.
