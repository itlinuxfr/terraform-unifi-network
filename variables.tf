variable "name" {
  description = "Name of the network, as shown in the UniFi controller."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "The network name must not be empty."
  }
}

variable "cidr" {
  description = "IPv4 network in CIDR notation, written as a network address (for example 192.0.2.0/27, not 192.0.2.5/27). The gateway is the first usable address unless gateway_ip says otherwise."
  type        = string
  nullable    = false

  validation {
    condition     = !strcontains(var.cidr, ":") && can(cidrhost(var.cidr, 0)) && can(regex("/[0-9]+$", var.cidr))
    error_message = "cidr must be an IPv4 network in CIDR notation, such as 192.0.2.0/27."
  }

  validation {
    condition     = can(cidrsubnet(var.cidr, 0, 0)) ? cidrsubnet(var.cidr, 0, 0) == var.cidr : true
    error_message = "cidr must be a network address: the bits after the prefix length must be zero (192.0.2.0/27, not 192.0.2.5/27)."
  }

  validation {
    condition     = can(regex("/[0-9]+$", var.cidr)) ? (tonumber(split("/", var.cidr)[1]) >= 8 && tonumber(split("/", var.cidr)[1]) <= 30) : true
    error_message = "The prefix length must be between 8 and 30: a gateway and at least one more address are needed."
  }
}

variable "gateway_ip" {
  description = "Gateway address of the network, without prefix length. Null uses the first usable address of cidr. It does not have to be the first one: 192.0.2.30 is valid in 192.0.2.0/27."
  type        = string
  default     = null

  validation {
    condition     = var.gateway_ip == null ? true : (!strcontains(var.gateway_ip, ":") && can(cidrhost("${var.gateway_ip}/32", 0)))
    error_message = "gateway_ip must be an IPv4 address without a prefix length."
  }
}

variable "vlan_id" {
  description = "VLAN ID of the network, from 1 to 4094. Null leaves the network untagged."
  type        = number
  default     = null

  validation {
    condition     = var.vlan_id == null ? true : (var.vlan_id >= 1 && var.vlan_id <= 4094 && floor(var.vlan_id) == var.vlan_id)
    error_message = "vlan_id must be an integer between 1 and 4094."
  }
}

variable "purpose" {
  description = "Network purpose: corporate, guest or vlan-only. A guest network only keeps its purpose while it belongs to the guest (Hotspot) zone, so it needs zone_id."
  type        = string
  default     = "corporate"
  nullable    = false

  validation {
    condition     = contains(["corporate", "guest", "vlan-only"], var.purpose)
    error_message = "purpose must be corporate, guest or vlan-only."
  }

  validation {
    condition     = var.purpose != "guest" || var.zone_id != null
    error_message = "A guest network must be put in the guest zone with zone_id: otherwise the controller rewrites its purpose to corporate and the apply fails."
  }
}

variable "zone_name" {
  description = "Create a firewall zone with this name and put the network in it. Needs a controller with zone-based firewall (UniFi Network 9 or later). Cannot be used with zone_id. Null creates no zone."
  type        = string
  default     = null

  validation {
    condition     = var.zone_name == null ? true : trimspace(var.zone_name) != ""
    error_message = "The zone name must not be empty."
  }

  validation {
    condition     = var.zone_name == null || var.zone_id == null
    error_message = "Use zone_name to create a zone or zone_id to join an existing one, not both."
  }
}

variable "zone_id" {
  description = "ID of an existing firewall zone to put the network in. Cannot be used with zone_name. With both null, the controller keeps its default zone."
  type        = string
  default     = null
}

variable "internet_access" {
  description = "Allow the network to reach the Internet. Null keeps the controller value, which is true for a new network."
  type        = bool
  default     = null
}

variable "network_isolation" {
  description = "Isolate the network from the other networks. Null keeps the controller value. With a dedicated zone, the zone does the isolation."
  type        = bool
  default     = null
}

variable "multicast_dns" {
  description = "Enable mDNS. Null keeps the controller value: some gateways ignore it and always store false."
  type        = bool
  default     = null
}

variable "igmp_snooping" {
  description = "Enable IGMP snooping. Null keeps the controller value."
  type        = bool
  default     = null
}

variable "dhcp" {
  description = <<-EOT
    DHCP server. Null leaves it to the controller.
    - enabled: run the DHCP server. Turn it off for a network whose addresses are set by hand.
    - start, stop: DHCP range. They default to the second and the last usable address. UniFi Network 11 refuses an empty range even when DHCP is off,
      so the module always sends one. Set them to a reserve at the end of the network when addresses are static, so the range never overlaps them.
    - dns_servers: DNS servers given to DHCP clients.
    - lease_time: lease time as a Go duration such as 24h.
  EOT
  type = object({
    enabled     = bool
    start       = optional(string)
    stop        = optional(string)
    dns_servers = optional(list(string), [])
    lease_time  = optional(string)
  })
  default = null

  validation {
    condition = var.dhcp == null ? true : alltrue([
      for ip in compact([var.dhcp.start, var.dhcp.stop]) : !strcontains(ip, ":") && can(cidrhost("${ip}/32", 0))
    ])
    error_message = "dhcp.start and dhcp.stop must be IPv4 addresses without a prefix length."
  }

  validation {
    condition     = var.dhcp == null ? true : (var.dhcp.start == null) == (var.dhcp.stop == null)
    error_message = "Set dhcp.start and dhcp.stop together, or neither."
  }

  validation {
    condition     = var.dhcp == null ? true : alltrue([for server in var.dhcp.dns_servers : !strcontains(server, ":") && can(cidrhost("${server}/32", 0))])
    error_message = "dhcp.dns_servers must be IPv4 addresses."
  }

  validation {
    condition     = var.dhcp == null || var.dhcp.lease_time == null ? true : can(regex("^[0-9]+(ns|us|ms|s|m|h)([0-9]+(ns|us|ms|s|m|h))*$", var.dhcp.lease_time))
    error_message = "dhcp.lease_time must be a Go duration such as 24h, 90m or 86400s."
  }
}
