# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver
resource "azurerm_private_dns_resolver" "this" {
  name                = "${var.project.customer}-${var.project.name}-${var.project.environment}-dnspr"
  location            = var.location
  resource_group_name = var.resource_group_name
  virtual_network_id  = var.virtual_network_id
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_inbound_endpoint
resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  name                    = "${var.project.customer}-${var.project.name}-${var.project.environment}-dnspr-ibe"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = var.subnet_dnspr_inbound_id
  }
}
