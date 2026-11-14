# Tests without a controller: the UniFi provider is replaced by a mock provider.
# `command = plan` creates nothing. Values that the controller computes (IDs) are not checked here.

mock_provider "unifi" {}

variables {
  name = "lab"
  cidr = "192.0.2.0/27"
}

run "minimal_network" {
  command = plan

  assert {
    condition = (
      unifi_network.this.name == "lab" &&
      unifi_network.this.subnet == "192.0.2.1/27" &&
      unifi_network.this.purpose == "corporate" &&
      unifi_network.this.vlan == null
    )
    error_message = "A minimal network must use the first usable address as gateway, the corporate purpose and no VLAN tag."
  }

  assert {
    condition     = length(unifi_firewall_zone.this) == 0 && unifi_network.this.dhcp_server == null
    error_message = "Without options no zone and no DHCP block must be created."
  }
}

run "vlan_and_dedicated_zone" {
  command = plan

  variables {
    vlan_id   = 700
    zone_name = "K8S-PROD"
  }

  assert {
    condition     = unifi_network.this.vlan == 700 && length(unifi_firewall_zone.this) == 1 && unifi_firewall_zone.this[0].name == "K8S-PROD"
    error_message = "The VLAN tag and a zone named K8S-PROD must be created."
  }
}

run "existing_zone" {
  command = plan

  variables {
    zone_id = "zone-123"
  }

  assert {
    condition     = unifi_network.this.firewall_zone_id == "zone-123" && length(unifi_firewall_zone.this) == 0
    error_message = "An existing zone must be used as is and no zone must be created."
  }
}

run "gateway_at_the_end_of_the_network" {
  command = plan

  variables {
    gateway_ip = "192.0.2.30"
  }

  assert {
    condition     = unifi_network.this.subnet == "192.0.2.30/27"
    error_message = "gateway_ip must be the host part of the subnet sent to the controller."
  }
}

run "static_network_with_dhcp_off_and_a_reserve" {
  command = plan

  variables {
    dhcp = { enabled = false, start = "192.0.2.20", stop = "192.0.2.30" }
  }

  assert {
    condition = (
      unifi_network.this.dhcp_server.enabled == false &&
      unifi_network.this.dhcp_server.start == "192.0.2.20" &&
      unifi_network.this.dhcp_server.stop == "192.0.2.30"
    )
    error_message = "DHCP must be off with the given reserve as range."
  }
}

run "dhcp_range_is_never_empty" {
  command = plan

  variables {
    dhcp = { enabled = false }
  }

  assert {
    condition     = unifi_network.this.dhcp_server.start == "192.0.2.2" && unifi_network.this.dhcp_server.stop == "192.0.2.30"
    error_message = "Without a range the module must send the second and the last usable addresses, because the controller refuses an empty range."
  }
}

run "dhcp_with_dns_and_lease" {
  command = plan

  variables {
    dhcp = { enabled = true, dns_servers = ["192.0.2.53", "192.0.2.54"], lease_time = "12h" }
  }

  assert {
    condition = (
      unifi_network.this.dhcp_server.enabled == true &&
      unifi_network.this.dhcp_server.leasetime == "12h" &&
      unifi_network.this.dhcp_server.dns.enabled == true &&
      unifi_network.this.dhcp_server.dns.servers == tolist(["192.0.2.53", "192.0.2.54"])
    )
    error_message = "DHCP DNS servers and the lease time must reach the controller."
  }
}

run "options_reach_the_controller" {
  command = plan

  variables {
    internet_access   = false
    network_isolation = true
    multicast_dns     = true
    igmp_snooping     = true
  }

  assert {
    condition = (
      unifi_network.this.internet_access == false &&
      unifi_network.this.network_isolation == true &&
      unifi_network.this.multicast_dns == true &&
      unifi_network.this.igmp_snooping == true
    )
    error_message = "internet_access, network_isolation, multicast_dns and igmp_snooping must reach the controller."
  }
}

run "guest_network_in_the_guest_zone" {
  command = plan

  variables {
    purpose = "guest"
    zone_id = "guest-zone"
  }

  assert {
    condition     = unifi_network.this.purpose == "guest" && unifi_network.this.firewall_zone_id == "guest-zone"
    error_message = "A guest network must keep its purpose and join the given zone."
  }
}
