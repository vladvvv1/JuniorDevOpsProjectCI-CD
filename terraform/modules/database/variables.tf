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

variable "snet_db_id" {
  type = string
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone id"
}

variable "db_admin_user" {
  type        = string
  description = "Database admin user"
}

variable "db_admin_password" {
  type        = string
  description = "Database admin password"
}

variable "dns_to_postgres_vnet_link" {
  type        = string
  description = "Link"
}