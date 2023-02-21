output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "private_dns_zones" {
  value = tomap({
    for private_dns_zone_key, private_dns_zone_name in var.private_dns_zones : private_dns_zone_key => {
      name = private_dns_zone_name
      id   = azurerm_private_dns_zone.this[private_dns_zone_key].id
    }
  })
}

output "subnet_dnspr_inbound_id" {
  value = azurerm_subnet.dnspr_inbound.id
}

output "subnet_gateway_id" {
  value = azurerm_subnet.gateway.id
}

output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}
