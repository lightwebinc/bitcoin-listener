output "provisioned_hosts" {
  description = "IPs of all provisioned listener nodes"
  value       = { for k, v in module.listener_nodes : k => v.host_ip }
}
