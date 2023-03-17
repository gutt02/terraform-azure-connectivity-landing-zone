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
