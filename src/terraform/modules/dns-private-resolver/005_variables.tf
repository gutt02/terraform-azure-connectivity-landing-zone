variable "location" {
  type        = string
  default     = "westeurope"
  description = "Default Azure region, use Azure CLI notation."
}

variable "project" {
  type = object({
    customer    = string
    name        = string
    environment = string
  })

  default = {
    customer    = "azc"
    name        = "clz"
    environment = "acf"
  }

  description = "Project details, like customer name, environment, etc."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the DNS Private Resolver deployment."
}

variable "subnet_dnspr_inbound_id" {
  type        = string
  description = "Id of the inbound subnet."
}

variable "virtual_network_id" {
  type        = string
  description = "Id of the Virtual Network for the DNS Private Resolver."
}
