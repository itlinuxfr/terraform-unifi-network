# terraform-unifi-network

Creates a UniFi network (a VLAN with its gateway address and DHCP settings) and, optionally, a firewall zone for it. It works with the
[`ubiquiti-community/unifi`](https://registry.terraform.io/providers/ubiquiti-community/unifi) provider and a controller with the zone-based firewall
(UniFi Network 9 or later). Firewall policies are not part of it: use `terraform-unifi-firewall`.

## Usage

```hcl
module "network" {
  source = "git::https://github.com/itlinuxfr/terraform-unifi-network.git?ref=v1.0.0"

  name      = "k8s-prod"
  cidr      = "192.0.2.0/27"
  vlan_id   = 700
  zone_name = "K8S-PROD"

  dhcp = { enabled = false, start = "192.0.2.20", stop = "192.0.2.30" }
}
```

See [`examples/`](examples/): a VLAN with a DHCP server, the static network of a cluster, and a guest network.

## What to know
- **The gateway** is the first usable address of `cidr`, unless `gateway_ip` says otherwise. `cidr` must be a network address (`192.0.2.0/27`).
- **The DHCP range is never empty.** UniFi Network 11 refuses an empty range even when DHCP is off. Without `start` and `stop` the module sends the second and the last
  usable addresses. For a network with static addresses, give a reserve at the end of the network so the range never overlaps them.
- **Settings left to `null` keep the controller value** (`internet_access`, `network_isolation`, `multicast_dns`, `igmp_snooping`, `dhcp`). The provider reads them back instead of
  overwriting them, so adopting an existing network does not change it.
- **Zone membership is set from the network side only** (`firewall_zone_id`). The module never fills `network_ids` of the zone, because managing both sides makes the provider plan the same change forever.
- **A guest network needs `zone_id`** of the guest zone: the controller rewrites the purpose of a guest network that is not in it, and the apply fails.
- The module does not check that the DHCP range or the gateway belongs to `cidr`: Terraform has no function for it. The controller rejects an address outside the network.
- The provider reads the credentials from its own configuration, never from this module.

## Contributing
Read [`AGENTS.md`](AGENTS.md) for conventions and commands, and [`SECURITY.md`](SECURITY.md) for security rules.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15 |
| <a name="requirement_unifi"></a> [unifi](#requirement\_unifi) | >= 0.62.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_unifi"></a> [unifi](#provider\_unifi) | >= 0.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [unifi_firewall_zone.this](https://registry.terraform.io/providers/ubiquiti-community/unifi/latest/docs/resources/firewall_zone) | resource |
| [unifi_network.this](https://registry.terraform.io/providers/ubiquiti-community/unifi/latest/docs/resources/network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr"></a> [cidr](#input\_cidr) | IPv4 network in CIDR notation, written as a network address (for example 192.0.2.0/27, not 192.0.2.5/27). The gateway is the first usable address unless gateway\_ip says otherwise. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the network, as shown in the UniFi controller. | `string` | n/a | yes |
| <a name="input_dhcp"></a> [dhcp](#input\_dhcp) | DHCP server. Null leaves it to the controller.<br/>- enabled: run the DHCP server. Turn it off for a network whose addresses are set by hand.<br/>- start, stop: DHCP range. They default to the second and the last usable address. UniFi Network 11 refuses an empty range even when DHCP is off,<br/>  so the module always sends one. Set them to a reserve at the end of the network when addresses are static, so the range never overlaps them.<br/>- dns\_servers: DNS servers given to DHCP clients.<br/>- lease\_time: lease time as a Go duration such as 24h. | <pre>object({<br/>    enabled     = bool<br/>    start       = optional(string)<br/>    stop        = optional(string)<br/>    dns_servers = optional(list(string), [])<br/>    lease_time  = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_gateway_ip"></a> [gateway\_ip](#input\_gateway\_ip) | Gateway address of the network, without prefix length. Null uses the first usable address of cidr. It does not have to be the first one: 192.0.2.30 is valid in 192.0.2.0/27. | `string` | `null` | no |
| <a name="input_igmp_snooping"></a> [igmp\_snooping](#input\_igmp\_snooping) | Enable IGMP snooping. Null keeps the controller value. | `bool` | `null` | no |
| <a name="input_internet_access"></a> [internet\_access](#input\_internet\_access) | Allow the network to reach the Internet. Null keeps the controller value, which is true for a new network. | `bool` | `null` | no |
| <a name="input_multicast_dns"></a> [multicast\_dns](#input\_multicast\_dns) | Enable mDNS. Null keeps the controller value: some gateways ignore it and always store false. | `bool` | `null` | no |
| <a name="input_network_isolation"></a> [network\_isolation](#input\_network\_isolation) | Isolate the network from the other networks. Null keeps the controller value. With a dedicated zone, the zone does the isolation. | `bool` | `null` | no |
| <a name="input_purpose"></a> [purpose](#input\_purpose) | Network purpose: corporate, guest or vlan-only. A guest network only keeps its purpose while it belongs to the guest (Hotspot) zone, so it needs zone\_id. | `string` | `"corporate"` | no |
| <a name="input_vlan_id"></a> [vlan\_id](#input\_vlan\_id) | VLAN ID of the network, from 1 to 4094. Null leaves the network untagged. | `number` | `null` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | ID of an existing firewall zone to put the network in. Cannot be used with zone\_name. With both null, the controller keeps its default zone. | `string` | `null` | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Create a firewall zone with this name and put the network in it. Needs a controller with zone-based firewall (UniFi Network 9 or later). Cannot be used with zone\_id. Null creates no zone. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cidr"></a> [cidr](#output\_cidr) | Network in CIDR notation. |
| <a name="output_gateway_ip"></a> [gateway\_ip](#output\_gateway\_ip) | Gateway address of the network. |
| <a name="output_name"></a> [name](#output\_name) | Name of the network. |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | ID of the network. Use it to match the network in a firewall policy. |
| <a name="output_vlan_id"></a> [vlan\_id](#output\_vlan\_id) | VLAN ID of the network, or null when untagged. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | ID of the firewall zone of the network: the zone created by the module, the zone\_id given, or null. |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Name of the firewall zone created by the module, or null when it created none. |
<!-- END_TF_DOCS -->
