# A VLAN with its own firewall zone and a normal DHCP server.
# In a real project, pin the module source to a tag:
#   source = "git::https://github.com/itlinuxfr/terraform-unifi-network.git?ref=v1.0.0"
# The relative source is used by CI: it tests the code of the current branch.

terraform {
  required_version = ">= 1.15"
}

module "network" {
  source = "../../"

  name      = "iot"
  cidr      = "192.0.2.0/24"
  vlan_id   = 20
  zone_name = "IOT"

  dhcp = {
    enabled     = true
    start       = "192.0.2.100"
    stop        = "192.0.2.199"
    dns_servers = ["192.0.2.53"]
    lease_time  = "12h"
  }
}

output "zone_id" {
  value = module.network.zone_id
}
