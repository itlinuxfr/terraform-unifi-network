output "network_id" {
  description = "ID of the network. Use it to match the network in a firewall policy."
  type        = string
  value       = unifi_network.this.id
}

output "name" {
  description = "Name of the network."
  type        = string
  value       = unifi_network.this.name
}

output "cidr" {
  description = "Network in CIDR notation."
  type        = string
  value       = var.cidr
}

output "gateway_ip" {
  description = "Gateway address of the network."
  type        = string
  value       = local.gateway_ip
}

output "vlan_id" {
  description = "VLAN ID of the network, or null when untagged."
  type        = number
  value       = var.vlan_id
}

output "zone_id" {
  description = "ID of the firewall zone of the network: the zone created by the module, the zone_id given, or null."
  type        = string
  value       = local.zone_id
}

output "zone_name" {
  description = "Name of the firewall zone created by the module, or null when it created none."
  type        = string
  value       = var.zone_name
}
