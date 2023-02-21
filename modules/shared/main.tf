terraform {
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.42.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
data "azurerm_client_config" "client_config" {
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription
data "azurerm_subscription" "subscription" {
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "this" {
  name     = "${var.project.customer}-${var.project.name}-${var.project.environment}-rg-net"
  location = var.location
  tags     = var.tags
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "this" {
  name                = "${var.project.customer}-${var.project.name}-${var.project.environment}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.virtual_network.address_space]
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "gateway" {
  name                 = var.virtual_network.subnets.gateway.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.virtual_network.subnets.gateway.address_space]

  service_endpoints = [
    "Microsoft.AzureCosmosDB",
    "Microsoft.CognitiveServices",
    "Microsoft.EventHub",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.Web"
  ]
}

resource "azurerm_subnet" "azure_bastion" {
  name                 = var.virtual_network.subnets.bastion.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.virtual_network.subnets.bastion.address_space]
}

resource "azurerm_subnet" "dnspr_inbound" {
  name                 = var.virtual_network.subnets.dnspr_inbound.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.virtual_network.subnets.dnspr_inbound.address_space]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  service_endpoints = [
    "Microsoft.AzureCosmosDB",
    "Microsoft.CognitiveServices",
    "Microsoft.EventHub",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.Web"
  ]

  lifecycle {
    ignore_changes = [
      delegation
    ]
  }
}

resource "azurerm_subnet" "dnspr_outbound" {
  name                 = var.virtual_network.subnets.dnspr_outbound.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.virtual_network.subnets.dnspr_outbound.address_space]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  service_endpoints = [
    "Microsoft.AzureCosmosDB",
    "Microsoft.CognitiveServices",
    "Microsoft.EventHub",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.Web"
  ]

  lifecycle {
    ignore_changes = [
      delegation
    ]
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "dnspr_inbound" {
  name                = "${var.project.customer}-${var.project.name}-${var.project.environment}-nsg-sn-${var.virtual_network.subnets.dnspr_inbound.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "dnspr_outbound" {
  name                = "${var.project.customer}-${var.project.name}-${var.project.environment}-nsg-sn-${var.virtual_network.subnets.dnspr_outbound.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}


# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association
resource "azurerm_subnet_network_security_group_association" "dnspr_inbound" {
  subnet_id                 = azurerm_subnet.dnspr_inbound.id
  network_security_group_id = azurerm_network_security_group.dnspr_inbound.id
}

resource "azurerm_subnet_network_security_group_association" "dnspr_outbound" {
  subnet_id                 = azurerm_subnet.dnspr_outbound.id
  network_security_group_id = azurerm_network_security_group.dnspr_outbound.id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone
# https://docs.microsoft.com/de-de/azure/private-link/private-endpoint-dns
resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns_zones

  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link
# Note: Create a link to each VNET which contains the Gateway and/or DNS resolver
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.private_dns_zones

  name                  = "${azurerm_virtual_network.this.name}-dnslnk"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
}

# modules
# module "dns_private_resolver" {
#   # source = "git@github.com:gutt02/terraform-azure-dns-private-resolver.git"
#   source = "git::https://github.com/gutt02/terraform-azure-dns-private-resolver.git"

#   location            = var.location
#   project             = var.project
#   resource_group_name = azurerm_resource_group.this.name
#   inbound_subnet_id   = azurerm_subnet.dnspr_inbound.id
#   virtual_network_id  = azurerm_virtual_network.this.id
# }

# module "virtual_network_gateway" {
#   # source = "git@github.com:gutt02/terraform-azure-virtual-network-gateway.git"
#   source = "git::https://github.com/gutt02/terraform-azure-virtual-network-gateway.git"

#   location                                   = var.location
#   project                                    = var.project
#   resource_group_name                        = azurerm_resource_group.this.name
#   subnet_gateway_id                          = azurerm_subnet.gateway.id
#   virtual_network_gateway                    = var.virtual_network_gateway
#   virtual_network_gateway_public_certificate = data.local_sensitive_file.p2s_root_cert.content
# }
