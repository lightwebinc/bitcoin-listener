# Networking

The `networking` role configures the **ingress** side of the listener —
the interface on which it joins multicast groups.

## Fabric address family

The multicast fabric is **IPv6-only**. Every multicast group, NACK target,
and listener-to-fabric BGP advertisement uses IPv6. IPv4 is used only
where unavoidable: public-internet management (SSH, metrics scrape) and
optionally the **outer** transport of a GRE tunnel when the fabric edge
is only reachable over the IPv4 Internet.

## Modes

### `ingress_mode: ethernet`

The listener joins IPv6 multicast groups directly on `ingress_iface`.
Deploys:

- `/etc/netplan/60-bitcoin-listener.yaml` — IPv6 on the ingress iface
  (DHCPv4 optional via `ingress_dhcp4`, defaults to `true` so a single-NIC
  host can still reach mgmt over v4; set `false` on multi-NIC or lab hosts
  where the ingress iface is dedicated to the fabric).
- `/etc/sysctl.d/60-bitcoin-listener.conf` — `accept_ra` settings to allow
  IPv6 autoconf.

No `ip -6 route add ff00::/8` is needed on the receive side: MLD joins
handle reception regardless of routing table. (The ingress proxy *does*
need this — it is the send side.)

### `ingress_mode: gre`

The listener receives multicast over a GRE tunnel. The **inner** payload
is always IPv6 (the fabric is IPv6-only). The **outer** transport may be
IPv4 or IPv6 — controlled by `gre_outer_proto`:

| `gre_outer_proto` | Linux tunnel type | FreeBSD    | Typical use                |
|-------------------|-------------------|------------|-----------------------------|
| `ipv6` (default)  | `ip6gre`          | `gif`/v6   | Fabric edge reachable via v6 |
| `ipv4`            | `gre`             | `gif`/v4   | Fabric edge only reachable over public IPv4 |

Deploys:

- `/etc/netplan/61-bitcoin-listener-gre.yaml` — tunnel definition +
  multicast route on the tunnel.
- When using this mode, set `ingress_iface: gre6-bsl` on each host so the
  listener joins groups on the tunnel interface.

Variables:

| Variable           | Meaning                                                     |
|--------------------|--------------------------------------------------------------|
| `gre_outer_proto`  | `ipv6` or `ipv4` — chooses the outer-transport address family |
| `gre_local_ip6`    | Local IPv6 outer endpoint (when `gre_outer_proto=ipv6`)       |
| `gre_remote_ip6`   | Remote IPv6 outer endpoint (when `gre_outer_proto=ipv6`)      |
| `gre_local_ip4`    | Local IPv4 outer endpoint (when `gre_outer_proto=ipv4`)       |
| `gre_remote_ip4`   | Remote IPv4 outer endpoint (when `gre_outer_proto=ipv4`)      |
| `gre_iface`        | Tunnel iface name (default `gre6-bsl`)                        |
| `gre_inner_ipv6`   | IPv6 address on the tunnel interface                          |

## Multicast route prefix

`mc_route_prefix` defaults to the FF0x::/16 corresponding to `mc_scope`:

| Scope    | Prefix      |
|----------|-------------|
| `link`   | `ff02::/16` |
| `site`   | `ff05::/16` |
| `org`    | `ff08::/16` |
| `global` | `ff0e::/16` |

Override `mc_route_prefix` when using an assigned narrower prefix (in
conjunction with `mc_base_addr`).

## BGP VIP

When `enable_bgp: true` and `bgp_vip` / `bgp_vip6` is set, a third netplan
file is deployed:

- `/etc/netplan/62-bitcoin-listener-vip.yaml` — VIP on loopback (`lo`).

The VIP is this listener's unicast identity inside the fabric.

## FreeBSD

On FreeBSD the role edits `/etc/rc.conf` directly:

- `ifconfig_<iface>` / `ifconfig_<iface>_ipv6` for ethernet
- `cloned_interfaces="gif0"` + `ifconfig_gif0*` for GRE mode
- `ifconfig_lo0_alias0` / `alias1` for BGP VIPs
- `ipv6_route_bsl_mcast` for the multicast route
- Restart via `service netif restart`

## Verifying multicast receive

```sh
# Linux — show joined groups
ip -6 maddr show dev eth0

# Inspect live receive
tcpdump -i eth0 -nn 'udp and ip6 multicast and port 9001'

# FreeBSD
netstat -g -f inet6
```
