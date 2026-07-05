# Ansible usage

## Layout

```
ansible/
  site.yml                  Main playbook (listener_nodes group)
  bgp-ibgp.yml              Upstream iBGP peer playbook (bgp_ibgp_nodes group)
  requirements.yml          Collection dependencies (community.general, ansible.posix)
  group_vars/all.yml        Default variables for all listener nodes
  inventory/hosts.example.yml
  roles/
    common/                 Base OS deps + Go toolchain
    perf-tuning/            High-PPS host tuning (UDP buffers, busy-poll, C-states)
    shard-listener/         Build + systemd / rc.d unit + config
    networking/             Interface / multicast route / VIP config
    firewall/               nftables (Linux) / pf (FreeBSD) perimeter
    bgp/                    BIRD2 or FRR + health-check + withdraw
    bgp-ibgp/               Upstream iBGP peer role (optional)
```

## First run

```sh
cd ansible
ansible-galaxy collection install -r requirements.yml
cp inventory/hosts.example.yml inventory/hosts.yml
$EDITOR inventory/hosts.yml               # fill in host IPs, ingress_iface, egress_addr
ansible-playbook -i inventory/hosts.yml site.yml
```

## Role ordering

`site.yml` runs roles in this order:

1. `common` — install packages, Go toolchain
2. `perf-tuning` — high-PPS host tuning (UDP buffers, busy-poll, C-states)
3. `shard-listener` — build binary, install service
4. `networking` — configure `ingress_iface`, GRE, BGP VIP
5. `firewall` *(when `enable_firewall: true`)* — lock down the fabric perimeter
6. `bgp` *(when `enable_bgp: true`)* — BIRD2 or FRR

Firewall runs **after** networking so interface names resolve, and **before**
BGP so TCP/179 is permitted when the daemon starts.

## Key variables

See `ansible/group_vars/all.yml` for the full list. Quick reference:

| Variable                   | Default          | Notes                                                  |
|----------------------------|------------------|--------------------------------------------------------|
| `ingress_iface`            | `eth0`           | **Must be set per-host** (group_vars precedence)       |
| `ingress_mode`             | `ethernet`       | Or `gre` (then set `ingress_iface: gre6-bsl`)          |
| `listen_port`              | `9001`           | Matches proxy's `egress_port`                          |
| `shard_bits`               | `2`              | Must match proxy                                       |
| `listener_mode`            | `collapsed`      | Or `receiver` / `delivery` (P3b role split)            |
| `source_mode`              | `asm`            | Or `ssm` (needs MLDv2 sysctls + `ssm_bootstrap_*`)     |
| `egress_addr`              | `127.0.0.1:9100` | Downstream consumer                                    |
| `egress_proto`             | `udp`            | Or `tcp`                                               |
| `retry_endpoints`          | `""`             | `"host:port,host:port"`                                |
| `num_workers`              | `0` (= NumCPU)   | **Set `1` per-host** for multicast receive (see note)  |
| `metrics_addr`             | `:9200`          |                                                        |
| `otlp_endpoint`            | `""`             |                                                        |
| `otlp_interval`            | `30s`            |                                                        |
| `enable_firewall`          | `true`           | Set `false` for labs only                              |
| `mgmt_cidrs_v4`            | `[]`             | **Must be set per-host**; SSH + metrics allow-list     |
| `enable_bgp`               | `false`          |                                                        |
| `bgp_local_as`             | `65002`          |                                                        |
| `bgp_health_path`          | `/healthz`       | Path bsl-bgp-check probes; `/readyz` for graceful drain |
| `header_mc_egress_enabled` | `false`          | BRC-135 block-header re-emission to a multicast group  |
| `header_mc_egress_iface`   | `""`             | NIC for BRC-135 egress; defaults to `ingress_iface`    |
| `header_egress_enabled`    | `false`          | BRC-135 block-header re-emission to a unicast/TCP sink |
| `egress_dedup_redis_addr`  | `""`             | Per-deployment egress dedup; empty = LRU-only          |
| `egress_dedup_prefix`      | `bsl:egr:`       | Redis key prefix; deployment-id appended downstream    |
| `ingress_set_redis_addr`   | `""`             | Courtesy mark to proxy's `bsp:tx:` namespace           |
| `ingress_set_prefix`       | `bsp:tx:`        | **Must match proxy's `txid_dedup_prefix`**             |

## Per-host overrides

Because `group_vars/all.yml` has higher precedence than inventory group vars,
the following must be set on each host (not in group vars):

- `ingress_iface`
- `num_workers` — **must be `1` for multicast receive** (see note below)
- `mgmt_cidrs_v4`, `mgmt_cidrs_v6` — firewall allow-list; `group_vars/all.yml` defaults to empty lists
- `ansible_host`, `ansible_user`, `ansible_ssh_private_key_file`
- `bgp_router_id`, `bgp_peer_ip`, `bgp_peer_ip6` (when `enable_bgp` is true)

> **`num_workers` and multicast:** Linux delivers multicast datagrams to every
> socket in a SO_REUSEPORT group — it does not load-balance them. Running
> `num_workers > 1` causes each frame to be processed and forwarded N times,
> doubling (or more) all metrics and egress traffic. Always set `num_workers: 1`
> as a **host-level** variable to override the `group_vars/all.yml` default of 0.

## Common operations

```sh
# Re-deploy listener code without touching firewall/networking
ansible-playbook site.yml --tags listener

# Update firewall after changing retry_endpoints
ansible-playbook site.yml --tags firewall

# Rotate BGP peer password
ansible-playbook site.yml --tags bgp -e bgp_password=...

# Apply high-PPS host tuning (UDP buffers, busy-poll, C-states, irqbalance)
ansible-playbook site.yml --tags perf-tuning

# Target one host
ansible-playbook site.yml -l listener-01
```

The `perf-tuning` role (run before `shard-listener`) applies the same
host-level network/CPU tunings as `ingress-infra`. Knobs live in
`roles/perf-tuning/defaults/main.yml`; see
[ingress-infra ansible.md](https://github.com/lightwebinc/ingress-infra/blob/main/docs/ansible.md#perf-tuning-role)
for the variable reference.

## Known issues (inherited from `ingress-infra`)

- Ubuntu LXD images may lack `acl` — installed by the `common` role.
- The `git` module fails in some LXD images with "unsafe repository"; the
  role marks `listener_install_dir` as `safe.directory` before cloning.
- Remember: `group_vars/all.yml` beats inventory-group vars. Always set
  `ingress_iface`, `num_workers`, and `mgmt_cidrs_*` on the host, not on the group.
- The binary build task runs on every playbook invocation (`changed_when: true`
  with no `creates:` guard) to ensure the installed binary always reflects the
  checked-out source. The `copy` step that follows only triggers a service
  restart when the binary actually changes.
