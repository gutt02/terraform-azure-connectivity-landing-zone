terraform {
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.42.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config
data "azurerm_client_config" "client_config" {
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription
data "azurerm_subscription" "subscription" {
}

# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file
# https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/sensitive_file
data "local_sensitive_file" "p2s_root_cert" {
  filename = "${path.module}/certificates/P2SRootCert.cer"
}

# https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "this" {
  name                = "${var.project.customer}-${var.project.name}-${var.project.environment}-vnetgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway
resource "azurerm_virtual_network_gateway" "this" {
  name                = "${var.project.customer}-${var.project.name}-${var.project.environment}-vnetgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.virtual_network_gateway.type
  vpn_type            = var.virtual_network_gateway.vpn_type
  active_active       = var.virtual_network_gateway.active_active
  enable_bgp          = var.virtual_network_gateway.enable_bgp
  sku                 = var.virtual_network_gateway.sku

  ip_configuration {
    name                          = "IpConfig"
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_gateway_id
  }

  vpn_client_configuration {
    address_space        = var.virtual_network_gateway.vpn_client_configuration.address_space
    vpn_client_protocols = var.virtual_network_gateway.vpn_client_configuration.vpn_client_protocols

    root_certificate {
      name             = var.virtual_network_gateway.vpn_client_configuration.root_certificate.name
      public_cert_data = data.local_sensitive_file.p2s_root_cert.content
    }
  }

  lifecycle {
    ignore_changes = [
      vpn_client_configuration # required, certificates uploaed manually
    ]
  }
}
