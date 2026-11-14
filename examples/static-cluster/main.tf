# The network of a Kubernetes cluster whose nodes have static addresses: the DHCP server is off, and its range is a reserve at the end of
# the network, so it never overlaps the addresses set by hand. Plan used here for a /27:
#   .1 gateway | .2 API virtual IP | .3-.9 nodes | .10-.19 load balancer | .20-.30 reserve
# The zone isolates the cluster: terraform-unifi-firewall then opens only what is needed (see its examples).

terraform {
  required_version = ">= 1.15"
}

module "network" {
  source = "../../"

  name      = "k8s-prod"
  cidr      = "192.0.2.0/27"
  vlan_id   = 700
  zone_name = "K8S-PROD"

  # The zone does the isolation, so the network itself is not isolated.
  network_isolation = false
  internet_access   = true

  dhcp = {
    enabled = false
    start   = "192.0.2.20"
    stop    = "192.0.2.30"
  }
}

output "network_id" {
  value = module.network.network_id
}

output "zone_id" {
  value = module.network.zone_id
}
