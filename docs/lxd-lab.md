# Deploying to an LXD lab

This guide covers deploying `bitcoin-shard-listener` onto LXD VMs using the
Ansible playbook in this repo. Written for use with
[bitcoin-multicast-test](https://github.com/lightwebinc/bitcoin-multicast-test)
but applies to any LXD-hosted Ubuntu 24.04 VM.

## Prerequisites

- LXD host with VMs running and reachable by SSH
- Ansible 2.15+ + collections (`ansible-galaxy collection install -r requirements.yml`)
- SSH key on the control machine
- An operational multicast fabric sending frames the listener can receive
  (e.g. a `bitcoin-ingress` proxy on the same LXD bridge)

## 1. Inject SSH key into target VMs

```bash
PUBKEY=$(cat ~/.ssh/id_ed25519.pub)
lxc exec listener -- bash -c "
  mkdir -p /home/ubuntu/.ssh && \
  echo '$PUBKEY' >> /home/ubuntu/.ssh/authorized_keys && \
  chmod 600 /home/ubuntu/.ssh/authorized_keys && \
  chown -R ubuntu:ubuntu /home/ubuntu/.ssh"
```

## 2. Create the inventory

Ubuntu 24.04 LXD VMs use predictable interface names (`enp5s0`, `enp6s0`),
not `eth0`. Set `ingress_iface` at the **host level** — `group_vars/all.yml`
takes higher precedence than inventory group vars.

```yaml
# ansible/inventory/hosts.yml
all:
  children:
    listener_nodes:
      vars:
        ansible_user: ubuntu
        ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
        ingress_mode: ethernet
        shard_bits: 2
        mc_scope: site
        enable_firewall: false    # Lab: skip perimeter for easier debug
        enable_bgp: false
      hosts:
        listener:
          ansible_host: 10.10.10.50
          ingress_iface: enp6s0   # host-level override required
          num_workers: 1          # host-level: Linux delivers multicast to all REUSEPORT sockets
          egress_addr: "10.10.10.100:9100"
```

**Production LXD labs should leave `enable_firewall: true`** and set
`mgmt_cidrs_v4` to the LXD bridge subnet.

## 3. Run the playbook

```bash
cd ansible/
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory/hosts.yml site.yml
```

The `common` role installs `acl`, Go, and build deps. The
`bitcoin-shard-listener` role clones, builds, and starts the service.

## 4. LXD bridge MLD querier (required)

MLD snooping without a querier floods multicast to all bridge ports. Enable
the querier on the LXD host (same as for `bitcoin-ingress`):

```bash
sudo sh -c 'echo 1 > /sys/devices/virtual/net/lxdbr1/bridge/multicast_querier'
# Persist via systemd — see bitcoin-ingress docs/lxd-lab.md for the unit file.
```

Without this, the listener may receive duplicates or see degraded delivery
depending on bridge topology.

## 5. Verify receive path

```bash
# Service and health
lxc exec listener -- systemctl status bitcoin-shard-listener
lxc exec listener -- curl -s http://localhost:9200/healthz
lxc exec listener -- curl -s http://localhost:9200/readyz

# Joined multicast groups
lxc exec listener -- ip -6 maddr show dev enp6s0

# Live traffic
lxc exec listener -- tcpdump -i enp6s0 -nn 'udp and ip6 multicast and port 9001' -c 8

# Forwarded counter (after proxy sends frames)
lxc exec listener -- curl -s http://localhost:9200/metrics | grep bsl_frames_forwarded_total
```

## Known issues (inherited)

| Issue | Fix |
|-------|-----|
| `git clone` "dubious ownership" | `community.general.git_config` sets `safe.directory` |
| `go build` VCS stamping error  | `-buildvcs=false` in build command |
| `ingress_iface` uses wrong default | Set at host level, not group `vars:` |
| `num_workers` uses wrong default | Set `num_workers: 1` at **host level** — `group_vars/all.yml` default of 0 = NumCPU; Linux delivers multicast to all REUSEPORT sockets so >1 worker produces duplicate frames |
| Binary not rebuilt on redeploy | Removed `creates:` guard from build task; binary is now always rebuilt on playbook run |
| Ansible `become` fails without ACL | `acl` package installed by `common` role |
| Multicast floods all receivers | Enable LXD bridge `multicast_querier` |

## Upgrade

```bash
ansible-playbook -i inventory/hosts.yml site.yml --tags listener \
  -e listener_version=v1.0.0
```
