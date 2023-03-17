# Client IPs could be empty
client_ips = [
  {
    name             = "ClientIP01",
    cidr             = "x.x.x.x/32"
    start_ip_address = "x.x.x.x"
    end_ip_address   = "x.x.x.x"
  }
]

# dns_private_resolver_enabled = true

on_premises_networks = [
  {
    name             = "AllowFromOnPremises1"
    cidr             = "10.0.0.0/24"
    start_ip_address = "10.0.0.0"
    end_ip_address   = "10.0.0.255"
  }
]

project = {
  customer          = "<Abbreviation of the customer>"
  name              = "<Abbreviation of the project>"
  environment       = "<Abbreviation of the environment>"
}

tags = {
  created_by  = "<Name of service principal>"
  contact     = "<E-mail address of the contact>"
  customer    = "<Full namem of the customer>"
  environment = "<Full name of the environment>"
  project     = "<Full name of the project>"
}

virtual_network = {
  # --------------------------------|--------------------|-----------------|-----------------|----
  #                                 | CIDR               | Start IP        | End IP          | IPs
  # --------------------------------|--------------------|-----------------|-----------------|----
  # VNET                            | xxx.xxx.0.0/24     | xxx.xxx.0.0     | xxx.xxx.0.255   | 256
  # --------------------------------|--------------------|-----------------|-----------------|----
  # GatewaySubnet                   | xxx.xxx.0.0/27     | xxx.xxx.0.0     | xxx.xxx.0.31    | 32
  # Azure Bastian                   | xxx.xxx.0.32/27    | xxx.xxx.0.32    | xxx.xxx.0.63    | 32
  # DNS Private Resolver Inbound    | xxx.xxx.0.64/28    | xxx.xxx.0.64    | xxx.xxx.0.79    | 16
  # DNS Private Resolver Output     | xxx.xxx.0.80/28    | xxx.xxx.0.80    | xxx.xxx.0.95    | 16
  # --------------------------------|--------------------|-----------------|-----------------|----

  address_space = "xxx.xxx.0.0/24"
  subnets = {
    gateway = {
      name                = "GatewaySubnet"
      address_space       = "xxx.xxx.0.0/27"
      client_address_pool = "xxx.xxx.255.0/27"
    },
    bastion = {
      name                = "AzureBastionSubnet"
      address_space       = "xxx.xxx.0.32/27"
    },
    dnspr_inbound = {
      name                = "DNSPrivateResolverInbound"
      address_space       = "xxx.xxx.0.64/28"
    },
    dnspr_outbound = {
      name                = "DNSPrivateResolverOutbound"
      address_space       = "xxx.xxx.0.80/28"
    },
  }
}

virtual_network_gateway = {
  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  vpn_client_configuration = {
    address_space        = ["<gateway.client_address_pool>"]
    vpn_client_protocols = ["IkeV2", "OpenVPN"]

    root_certificate = {
      name = "VnetGatewayConfig"
    }
  }
}
