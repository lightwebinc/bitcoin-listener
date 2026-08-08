# Debian 13 (Trixie)

Debian 13 is a first-class deployment target. Service management, netplan
layout, BGP daemon paths, firewall, and package installation are identical to
[Ubuntu 24.04](ubuntu-24.04.md) — both are `ansible_os_family: Debian`, so the
Ansible roles run the same task set. This page lists only the differences.

## Differences from Ubuntu

- **netplan is not preinstalled.** The `networking` role installs `netplan.io`
  and enables `systemd-networkd` (the netplan renderer) on Debian. Rendered
  runtime config lands in `/run/systemd/network/10-netplan-*` exactly as on
  Ubuntu.
- **Cloud images render networkd directly.** Debian cloud/LXD images ship
  without netplan or ifupdown — cloud-init writes
  `/etc/systemd/network/*.network`. These coexist with netplan-rendered files
  as long as they configure *different* interfaces (the roles only manage the
  ingress interfaces). If cloud-init manages the same interface the roles do,
  disable its network rendering
  (`/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`).
- **Kernel.** The stock Debian 13 kernel (6.12 LTS) passes the full multicast
  validation (ip6gre mesh replication, SSM `MCAST_JOIN_SOURCE_GROUP` joins,
  MLDv2 source filters). No backports kernel is required; `trixie-backports`
  provides newer kernels if a specific NIC driver needs one.
- **FRR.** Debian's stock `frr` (10.x) is far newer than Ubuntu 24.04's
  (8.4.4) and, unlike Ubuntu's, ships `pim6d`. The `bgp` role installs the
  distro package on both; either provides the `bgpd` used here.
- **BIRD2.** `bird2` 2.17.x from the trixie repo; same config paths.
- **Minimal images.** Debian cloud images omit `curl`; the `common` role
  installs it with the build dependencies before anything needs it.
