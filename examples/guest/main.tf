# A guest network. On a zone-based firewall controller, a guest network keeps its purpose only while it belongs to the guest (Hotspot) zone,
# so the zone is looked up by name and passed with zone_id.

terraform {
  required_version = ">= 1.15"

  # Declared here because this root module uses a data source of the provider itself.
  required_providers {
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = ">= 0.62.0"
    }
  }
}

data "unifi_firewall_zone" "guest" {
  name = "Hotspot"
}

module "network" {
  source = "../../"

  name    = "guests"
  cidr    = "192.0.2.0/24"
  vlan_id = 30
  purpose = "guest"
  zone_id = data.unifi_firewall_zone.guest.id

  dhcp = {
    enabled = true
    start   = "192.0.2.50"
    stop    = "192.0.2.250"
  }
}
