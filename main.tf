# Creates a UniFi network (a VLAN with its gateway address and DHCP settings) and, optionally, a firewall zone for it.
# Firewall policies are not part of this module: terraform-unifi-firewall adds them.

locals {
  prefix_length = tonumber(split("/", var.cidr)[1])
  gateway_ip    = var.gateway_ip != null ? var.gateway_ip : cidrhost(var.cidr, 1)

  # The second and the last usable addresses: the range is never empty (see the dhcp variable).
  dhcp_start = var.dhcp == null ? null : (var.dhcp.start != null ? var.dhcp.start : cidrhost(var.cidr, 2))
  dhcp_stop  = var.dhcp == null ? null : (var.dhcp.stop != null ? var.dhcp.stop : cidrhost(var.cidr, -2))

  zone_id = var.zone_name != null ? unifi_firewall_zone.this[0].id : var.zone_id
}

# The zone is not given network_ids: the network carries the membership through firewall_zone_id. Managing it from both
# sides makes the provider fight itself and plan the same change forever.
resource "unifi_firewall_zone" "this" {
  count = var.zone_name != null ? 1 : 0

  name = var.zone_name
}

resource "unifi_network" "this" {
  name    = var.name
  purpose = var.purpose
  vlan    = var.vlan_id
  subnet  = "${local.gateway_ip}/${local.prefix_length}"

  firewall_zone_id  = local.zone_id
  internet_access   = var.internet_access
  network_isolation = var.network_isolation
  multicast_dns     = var.multicast_dns
  igmp_snooping     = var.igmp_snooping

  dhcp_server = var.dhcp == null ? null : {
    enabled   = var.dhcp.enabled
    start     = local.dhcp_start
    stop      = local.dhcp_stop
    leasetime = var.dhcp.lease_time
    dns       = length(var.dhcp.dns_servers) > 0 ? { enabled = true, servers = var.dhcp.dns_servers } : null
  }
}
