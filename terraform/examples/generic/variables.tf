variable "hosts" {
  description = "List of target hosts. Per-host optional fields: egress_addr, gre_local_ip6, gre_inner_ipv6, bgp_peer_ip, bgp_peer_ip6."
  type = list(object({
    name           = string
    public_ip      = string
    ssh_user       = string
    ssh_key        = string
    egress_addr    = optional(string, "")
    gre_local_ip6  = optional(string, "")
    gre_inner_ipv6 = optional(string, "")
    bgp_peer_ip    = optional(string, "")
    bgp_peer_ip6   = optional(string, "")
  }))
}

variable "shard_bits" {
  description = "Shard bit width (1-24); must match proxy"
  type        = number
  default     = 2
}

variable "ingress_iface" {
  description = "Multicast ingress interface name"
  type        = string
  default     = "eth0"
}

variable "ingress_mode" {
  description = "Ingress interface mode: ethernet or gre"
  type        = string
  default     = "ethernet"
}

variable "mc_route_prefix" {
  description = "IPv6 multicast route prefix (empty = auto-derive from mc_scope)"
  type        = string
  default     = ""
}

variable "egress_addr" {
  description = "Downstream unicast host:port (default, overridable per host)"
  type        = string
  default     = "127.0.0.1:9100"
}

variable "egress_proto" {
  description = "Egress protocol: udp or tcp"
  type        = string
  default     = "udp"
}

variable "retry_endpoints" {
  description = "Comma-separated host:port retry nodes for NACK dispatch"
  type        = string
  default     = ""
}

variable "gre_remote_ip6" {
  description = "Remote IPv6 endpoint for ip6gre tunnel (ingress_mode=gre, shared across hosts)"
  type        = string
  default     = ""
}

# Firewall
variable "enable_firewall" {
  description = "Enable multicast-fabric perimeter firewall (default on)"
  type        = bool
  default     = true
}

variable "mgmt_cidrs_v4" {
  description = "IPv4 CIDR allow-list for SSH / metrics"
  type        = list(string)
  default     = []
}

variable "mgmt_cidrs_v6" {
  description = "IPv6 CIDR allow-list for SSH / metrics"
  type        = list(string)
  default     = []
}

# BGP
variable "enable_bgp" {
  description = "Enable eBGP"
  type        = bool
  default     = false
}

variable "bgp_daemon" {
  description = "BGP daemon: bird2 or frr"
  type        = string
  default     = "bird2"
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
  description = "IPv4 loopback VIP (listener identity)"
  type        = string
  default     = ""
}

variable "bgp_vip6" {
  description = "IPv6 loopback VIP (listener identity)"
  type        = string
  default     = ""
}

variable "bgp_local_as" {
  description = "Local BGP ASN"
  type        = number
  default     = 65002
}

variable "bgp_peer_as" {
  description = "Upstream provider BGP ASN"
  type        = number
  default     = 65000
}

variable "bgp_peer_ip" {
  description = "Upstream BGP peer IPv4 address (default, overridable per host)"
  type        = string
  default     = ""
}

variable "bgp_peer_ip6" {
  description = "Upstream BGP peer IPv6 address (default, overridable per host)"
  type        = string
  default     = ""
}

variable "bgp_password" {
  description = "Optional MD5 BGP session password"
  type        = string
  default     = ""
  sensitive   = true
}
