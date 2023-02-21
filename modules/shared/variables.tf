locals {
  # detect OS
  # Directories start with "C:..." on Windows; All other OSs use "/" for root.
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}

# curl ipinfo.io/ip
variable "agent_ip" {
  type        = string
  description = "IP of the deployment agent."
}

# curl ipinfo.io/ip
variable "client_ip" {
  type = object({
    name             = string
    cidr             = string
    start_ip_address = string
    end_ip_address   = string
  })

  default = {
    name             = "ClientIP01"
    cidr             = "93.228.115.13/32"
    start_ip_address = "93.228.115.13"
    end_ip_address   = "93.228.115.13"
  }

  description = "Client IP."
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Client secret of the service principal."
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Default Azure region, use Azure CLI notation."
}

// See ASY nets here: https://ipinfo.io/AS33873
variable "on_premises_networks" {
  type = list(object({
    name             = string
    cidr             = string
    start_ip_address = string
    end_ip_address   = string
  }))

  default = [
    {
      name             = "AllowFromOnPremises1"
      cidr             = "84.17.160.0/19"
      start_ip_address = "84.17.160.0"
      end_ip_address   = "84.17.191.255"
    },
    {
      name             = "AllowFromOnPremises2"
      cidr             = "109.235.136.0/21"
      start_ip_address = "109.235.136.0"
      end_ip_address   = "109.235.143.255"
    },
    {
      name             = "AllowFromOnPremises3"
      cidr             = "145.228.0.0/16"
      start_ip_address = "145.228.0.0"
      end_ip_address   = "145.228.255.255"
    }
  ]

  description = "List of ASY networks, https://ipinfo.io/AS33873."
}

variable "private_dns_zones" {
  type = map(string)

  default = {
    dns_zone_adf                       = "privatelink.adf.azure.com"
    dns_zone_agentsvc_azure_automation = "privatelink.agentsvc.azure-automation.net"
    dns_zone_azure_automation          = "privatelink.azure-automation.net"
    dns_zone_azuredatabricks           = "privatelink.azuredatabricks.net"
    dns_zone_azure_devices             = "privatelink.azure-devices.net"
    dns_zone_azuresynapse              = "privatelink.azuresynapse.net"
    dns_zone_blob                      = "privatelink.blob.core.windows.net"
    dns_zone_database                  = "privatelink.database.windows.net"
    dns_zone_datafactory               = "privatelink.datafactory.azure.net"
    dns_zone_dev_azuresynapse          = "privatelink.dev.azuresynapse.net"
    dns_zone_dfs                       = "privatelink.dfs.core.windows.net"
    dns_zone_file                      = "privatelink.file.core.windows.net"
    dns_zone_monitor                   = "privatelink.monitor.azure.com"
    dns_zone_oms_opinsights            = "privatelink.oms.opinsights.azure.com"
    dns_zone_ods_opinsights            = "privatelink.ods.opinsights.azure.com"
    dns_zone_queue                     = "privatelink.queue.core.windows.net"
    dns_zone_servicebus                = "privatelink.servicebus.windows.net"
    dns_zone_sql                       = "privatelink.sql.azuresynapse.net"
    dns_zone_table                     = "privatelink.table.core.windows.net"
    dns_zone_vaultcore                 = "privatelink.vaultcore.azure.net"
  }

  description = "Map of private DNS zones."
}

variable "project" {
  type = object({
    customer    = string
    name        = string
    environment = string
  })

  default = {
    customer    = "azc"
    name        = "hub"
    environment = "vse"
  }

  description = "Project details, like customer name, environment, etc."
}

variable "tags" {
  type = object({
    created_by  = string
    contact     = string
    customer    = string
    environment = string
    project     = string
  })

  default = {
    created_by  = "vsp-base-msdn-sp-tf"
    contact     = "contact@me"
    customer    = "Azure Cloud"
    environment = "Visual Studio Enterprise"
    project     = "Hub"
  }

  description = "Default tags for resources, only applied to resource groups"
}


# --------------------------------|--------------------|-----------------|-----------------|----
#                                 | CIDR               | Start IP        | End IP          | IPs
# --------------------------------|--------------------|-----------------|-----------------|----
# VNET                            | 192.168.0.0/24     | 192.168.0.0     | 192.168.0.255   | 256
# --------------------------------|--------------------|-----------------|-----------------|----
# GatewaySubnet                   | 192.168.0.0/27     | 192.168.0.0     | 192.168.0.31    | 32
# Azure Bastian Subnet            | 192.168.0.32/27    | 192.168.0.32    | 192.168.0.63    | 32
# DNS Private Resolver Inbound    | 192.168.0.64/28    | 192.168.0.64    | 192.168.0.79    | 16
# DNS Private Resolver Output     | 192.168.0.80/28    | 192.168.0.80    | 192.168.0.95    | 16
# --------------------------------|--------------------|-----------------|-----------------|----
variable "virtual_network" {
  type = object({
    address_space = string

    subnets = map(object({
      name                = string
      address_space       = string
      client_address_pool = optional(string)
    }))
  })

  default = {
    address_space = "192.168.0.0/24"

    subnets = {
      gateway = {
        name                = "GatewaySubnet"
        address_space       = "192.168.0.0/27"
        client_address_pool = "192.168.255.0/27"
      },
      bastion = {
        name          = "AzureBastionSubnet"
        address_space = "192.168.0.32/27"
      },
      dnspr_inbound = {
        name          = "DNSPrivateResolverInbound"
        address_space = "192.168.0.64/28"
      },
      dnspr_outbound = {
        name          = "DNSPrivateResolverOutbound"
        address_space = "192.168.0.80/28"
      }
    }
  }

  description = "VNET destails."
}
