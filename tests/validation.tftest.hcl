# Input validation tests: each rejected value must fail the plan on the right variable.

mock_provider "unifi" {}

variables {
  name = "lab"
  cidr = "192.0.2.0/27"
}

run "empty_name_refused" {
  command = plan
  variables {
    name = " "
  }
  expect_failures = [var.name]
}

run "cidr_without_prefix_refused" {
  command = plan
  variables {
    cidr = "192.0.2.0"
  }
  expect_failures = [var.cidr]
}

run "ipv6_cidr_refused" {
  command = plan
  variables {
    cidr = "2001:db8::/64"
  }
  expect_failures = [var.cidr]
}

run "cidr_with_host_bits_refused" {
  command = plan
  variables {
    cidr = "192.0.2.5/27"
  }
  expect_failures = [var.cidr]
}

run "prefix_too_long_refused" {
  command = plan
  variables {
    cidr = "192.0.2.0/31"
  }
  expect_failures = [var.cidr]
}

run "prefix_too_short_refused" {
  command = plan
  variables {
    cidr = "10.0.0.0/7"
  }
  expect_failures = [var.cidr]
}

run "gateway_with_prefix_refused" {
  command = plan
  variables {
    gateway_ip = "192.0.2.1/27"
  }
  expect_failures = [var.gateway_ip]
}

run "ipv6_gateway_refused" {
  command = plan
  variables {
    gateway_ip = "2001:db8::1"
  }
  expect_failures = [var.gateway_ip]
}

run "vlan_zero_refused" {
  command = plan
  variables {
    vlan_id = 0
  }
  expect_failures = [var.vlan_id]
}

run "vlan_above_4094_refused" {
  command = plan
  variables {
    vlan_id = 4095
  }
  expect_failures = [var.vlan_id]
}

run "invalid_purpose_refused" {
  command = plan
  variables {
    purpose = "iot"
  }
  expect_failures = [var.purpose]
}

run "guest_without_zone_refused" {
  command = plan
  variables {
    purpose = "guest"
  }
  expect_failures = [var.purpose]
}

run "empty_zone_name_refused" {
  command = plan
  variables {
    zone_name = ""
  }
  expect_failures = [var.zone_name]
}

run "zone_name_and_zone_id_together_refused" {
  command = plan
  variables {
    zone_name = "LAB"
    zone_id   = "zone-123"
  }
  expect_failures = [var.zone_name]
}

run "dhcp_start_without_stop_refused" {
  command = plan
  variables {
    dhcp = { enabled = false, start = "192.0.2.20" }
  }
  expect_failures = [var.dhcp]
}

run "dhcp_range_with_invalid_address_refused" {
  command = plan
  variables {
    dhcp = { enabled = false, start = "192.0.2.999", stop = "192.0.2.30" }
  }
  expect_failures = [var.dhcp]
}

run "dhcp_dns_server_with_hostname_refused" {
  command = plan
  variables {
    dhcp = { enabled = true, dns_servers = ["dns.example.test"] }
  }
  expect_failures = [var.dhcp]
}

run "dhcp_lease_time_without_unit_refused" {
  command = plan
  variables {
    dhcp = { enabled = true, lease_time = "86400" }
  }
  expect_failures = [var.dhcp]
}

run "dhcp_lease_time_in_compound_units_accepted" {
  command = plan
  variables {
    dhcp = { enabled = true, lease_time = "1h30m" }
  }
}
