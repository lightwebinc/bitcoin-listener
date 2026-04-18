variable "ansible_inventory_path" {
  description = "Path to write the generated Ansible inventory file"
  type        = string
  default     = ""
}

variable "ansible_playbook_path" {
  description = "Absolute path to the Ansible site.yml playbook"
  type        = string
  default     = ""
}

variable "host_ip" {
  description = "Public IP address of the target host"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}

variable "ssh_user" {
  description = "SSH username for the target host"
  type        = string
  default     = "ubuntu"
}

# Listener source
variable "listener_repo" {
  description = "Git URL of the bitcoin-shard-listener repository"
  type        = string
  default     = "https://github.com/lightwebinc/bitcoin-shard-listener.git"
}

variable "listener_version" {
  description = "Git ref (branch, tag, or SHA) to check out"
  type        = string
  default     = "main"
}

# Listener runtime
variable "listen_port" {
  description = "UDP port for incoming multicast frames"
  type        = number
  default     = 9001
}

variable "shard_bits" {
  description = "Shard bit width (1-24); must match proxy"
  type        = number
  default     = 2
}

variable "mc_scope" {
  description = "Multicast scope: link, site, org, or global"
  type        = string
  default     = "site"
}

variable "mc_base_addr" {
  description = "Optional assigned IPv6 base address for multicast groups"
  type        = string
  default     = ""
}

variable "mc_route_prefix" {
  description = "IPv6 multicast route prefix for the ingress interface (empty = auto-derive from mc_scope)"
  type        = string
  default     = ""
}

variable "shard_include" {
  description = "Comma-separated shard indices to subscribe, e.g. \"0,1\" (empty = all 2^shard_bits groups; strongly recommend setting this explicitly in production)"
  type        = string
  default     = ""
}

variable "subtree_include" {
  description = "Comma-separated hex subtree IDs to allow (V2 only; empty = all)"
  type        = string
  default     = ""
}

variable "subtree_exclude" {
  description = "Comma-separated hex subtree IDs to drop (V2 only; empty = none)"
  type        = string
  default     = ""
}

variable "egress_addr" {
  description = "Downstream unicast host:port for forwarded frames"
  type        = string
  default     = "127.0.0.1:9100"
}

variable "egress_proto" {
  description = "Egress protocol: udp or tcp"
  type        = string
  default     = "udp"

  validation {
    condition     = contains(["udp", "tcp"], var.egress_proto)
    error_message = "egress_proto must be 'udp' or 'tcp'."
  }
}

variable "strip_header" {
  description = "Send payload-only datagrams (drop frame header)"
  type        = bool
  default     = false
}

variable "retry_endpoints" {
  description = "Comma-separated host:port retry nodes for NACK dispatch"
  type        = string
  default     = ""
}

variable "nack_jitter_max" {
  description = "Max NACK suppression jitter (Go duration)"
  type        = string
  default     = "200ms"
}

variable "nack_backoff_max" {
  description = "Max NACK backoff per gap (Go duration)"
  type        = string
  default     = "5s"
}

variable "nack_max_retries" {
  description = "Max NACK attempts per gap"
  type        = number
  default     = 5
}

variable "nack_gap_ttl" {
  description = "Max gap entry lifetime (Go duration)"
  type        = string
  default     = "10m"
}

variable "metrics_addr" {
  description = "HTTP bind address for /metrics, /healthz, /readyz"
  type        = string
  default     = ":9200"
}

variable "otlp_endpoint" {
  description = "OTLP gRPC endpoint for metric push (empty = disabled)"
  type        = string
  default     = ""
}

variable "otlp_interval" {
  description = "OTLP metric export interval (Go duration)"
  type        = string
  default     = "30s"
}

# Networking (ingress / multicast-receive side)
variable "ingress_iface" {
  description = "Multicast ingress interface (per host). For GRE mode use gre_iface (default 'gre6-bsl')."
  type        = string
  default     = "eth0"
}

variable "ingress_mode" {
  description = "Ingress interface mode: ethernet or gre"
  type        = string
  default     = "ethernet"

  validation {
    condition     = contains(["ethernet", "gre"], var.ingress_mode)
    error_message = "ingress_mode must be 'ethernet' or 'gre'."
  }
}

variable "gre_local_ip6" {
  description = "Local IPv6 address for the ip6gre tunnel endpoint (ingress_mode=gre only)"
  type        = string
  default     = ""
}

variable "gre_remote_ip6" {
  description = "Remote IPv6 address for the ip6gre tunnel endpoint (ingress_mode=gre only)"
  type        = string
  default     = ""
}

variable "gre_inner_ipv6" {
  description = "IPv6 address/prefix assigned to the tunnel interface"
  type        = string
  default     = ""
}

# Firewall (multicast-fabric perimeter)
variable "enable_firewall" {
  description = "Enable nftables/pf perimeter rules (default on for security)"
  type        = bool
  default     = true
}

variable "mgmt_cidrs_v4" {
  description = "IPv4 CIDR allow-list for SSH / metrics scrape (non-fabric ifaces only)"
  type        = list(string)
  default     = []
}

variable "mgmt_cidrs_v6" {
  description = "IPv6 CIDR allow-list for SSH / metrics scrape (non-fabric ifaces only)"
  type        = list(string)
  default     = []
}

# BGP (optional) — listener-reachability advertisement into the fabric only.
# Downstream-consumer anycast is NOT supported here.
variable "enable_bgp" {
  description = "Enable eBGP"
  type        = bool
  default     = false
}

variable "bgp_daemon" {
  description = "BGP daemon: bird2 or frr"
  type        = string
  default     = "bird2"

  validation {
    condition     = contains(["bird2", "frr"], var.bgp_daemon)
    error_message = "bgp_daemon must be 'bird2' or 'frr'."
  }
}

variable "bgp_prefix" {
  description = "IPv4 prefixes advertised into the fabric"
  type        = list(string)
  default     = []
}

variable "bgp_prefix6" {
  description = "IPv6 prefixes advertised into the fabric"
  type        = list(string)
  default     = []
}

variable "bgp_vip" {
  description = "IPv4 loopback VIP — listener identity (NOT shared anycast)"
  type        = string
  default     = ""
}

variable "bgp_vip6" {
  description = "IPv6 loopback VIP — listener identity (NOT shared anycast)"
  type        = string
  default     = ""
}

variable "bgp_local_as" {
  description = "Local BGP ASN (listener default 65002)"
  type        = number
  default     = 65002
}

variable "bgp_peer_as" {
  description = "Upstream provider BGP ASN"
  type        = number
  default     = 65000
}

variable "bgp_peer_ip" {
  description = "Upstream BGP peer IPv4 address"
  type        = string
  default     = ""
}

variable "bgp_peer_ip6" {
  description = "Upstream BGP peer IPv6 address"
  type        = string
  default     = ""
}

variable "bgp_router_id" {
  description = "BGP router ID (defaults to host_ip)"
  type        = string
  default     = ""
}

variable "bgp_password" {
  description = "Optional MD5 BGP session password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "extra_ansible_vars" {
  description = "Additional Ansible variables to pass as --extra-vars"
  type        = map(any)
  default     = {}
}
