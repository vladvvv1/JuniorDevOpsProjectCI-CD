variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group"
}

variable "resource_name_prefix" {
  type        = string
  description = "Prefix of resource name"
}

variable "acr_id" {
  type        = string
  description = "Acr id"
}

variable "aks_subnet_id" {
  type        = string
  description = "ID of ask subnet"
}



variable "database_portfolio" {
  type        = string
  description = "PostgreSQL flexible server portfolio database"
}