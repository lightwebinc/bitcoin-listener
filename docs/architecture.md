# Architecture

`bitcoin-listener` is the deployment/operations repo for
[`bitcoin-shard-listener`](https://github.com/lightwebinc/bitcoin-shard-listener) — the
inverse side of the `bitcoin-ingress` / `bitcoin-shard-proxy` pipeline. Where
the ingress proxy *sends* sharded transaction frames into an IPv6 multicast
fabric, the listener *receives* those frames, filters by shard / subtree, and
forwards matching frames as unicast to downstream consumers.

```
       ┌───────────────┐     IPv6 multicast fabric     ┌────────────────┐
       │ shard-proxy   │ ───►  (FF0x::/16, UDP 9001)  ──► shard-listener│
       │ (ingress)     │                                │                │
       └───────────────┘                                └──────┬─────────┘
                                                               │ unicast
                                                               ▼
                                                     ┌─────────────────┐
                                                     │ consumer        │
                                                     │ (egress_addr)   │
                                                     └─────────────────┘

                NACK (UDP, send-only):
                  shard-listener ──► retry-endpoints
```

## Data plane

1. **Ingress interface** (`ingress_iface` / `gre6-bsl`) joins the per-shard
   IPv6 multicast groups via MLD. The listener receives frames directly on
   this interface; no routing-table entry is required on the receive side
   (unlike the proxy's send path, which needs `ff00::/8` routed to
   `egress_iface`).
2. **Shard and subtree filters** discard non-matching frames in user space.
3. **NACK tracker** (NORM-inspired) detects sequence gaps per
   `(SenderID, groupIdx)` and dispatches 64-byte NACK datagrams via UDP to
   configured `retry_endpoints`. NACK is **send-only** — the retry node
   re-multicasts missing frames, which the listener receives on its normal
   multicast path.
4. **Downstream egress** unicasts accepted frames over UDP or TCP to
   `egress_addr`. `strip_header=true` emits payload only.

## Control plane

- **BGP** (optional) advertises *this listener's own unicast prefix* into the
  fabric so MLD/PIM can build distribution trees toward the node in L3
  fabrics. The loopback VIP (`bgp_vip`/`bgp_vip6`) is the listener's
  identity — **not** a shared anycast address. Downstream-consumer anycast
  is explicitly out of scope; the service-provider / consumer demarcation
  lives at the multicast fabric edge, not the listener.
- **Metrics** (Prometheus + OTLP) exposed on `:9200/healthz`, `:9200/readyz`,
  `:9200/metrics`. `OTLP_INTERVAL` controls the push cadence (default 30 s).
- **Firewall** (nftables on Linux, pf on FreeBSD) enforces the
  multicast-fabric perimeter. See `security.md`.

## How this repo is organised

| Layer      | Location          | Purpose                                           |
|------------|-------------------|---------------------------------------------------|
| Ansible    | `ansible/`        | Roles + playbooks for provisioning                |
| Terraform  | `terraform/`      | Node module + AWS / generic examples              |
| Docs       | `docs/`           | Architecture, ops, security, BGP, networking, OS  |

## Relationship to `bitcoin-ingress`

| Concern        | `bitcoin-ingress` (proxy)      | `bitcoin-listener` (this repo) |
|----------------|--------------------------------|---------------------------------|
| Direction      | TX onto fabric                 | RX from fabric                  |
| Primary iface  | `egress_iface` (send)          | `ingress_iface` (receive)       |
| Needs `ExecStartPre ip -6 route add ff00::/8` | **Yes** | **No** (MLD-only) |
| Default AS     | `65001`                        | `65002`                         |
| Metrics port   | `:9100`                        | `:9200`                         |
| Listen port    | `9000` UDP                     | `9001` UDP (matches proxy egress) |
| BGP role       | Anycast + reachability         | Listener-reachability **only**  |
| Firewall role  | n/a                            | Built-in `firewall` Ansible role |

Shared patterns: Go toolchain install, systemd unit hardening, netplan-based
interface config on Ubuntu, rc.d on FreeBSD, BGP via BIRD2 or FRR,
management-plane helpers (`bsp-*` / `bsl-*`).
