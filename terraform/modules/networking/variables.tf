variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network"
  default     = "main-VNet-name"
}

variable "resource_name_prefix" {
  type        = string
  description = "Prefix name of resource"
}

variable "resource_group_name" {
  type        = string
  description = "Name of resource group name"
}

variable "resource_group_location" {
  type        = string
  description = "Name of resource group location"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space of vnet"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "List of address prefixes for subnets"
}

variable "network_security_prefix" {
  type        = string
  description = "Network security prefix name"
}