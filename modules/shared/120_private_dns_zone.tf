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
