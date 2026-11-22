variable "environment" {
  type        = string
  description = "Env name"
  default     = "dev"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "app-rg"
}

variable "resource_group_location" {
  type        = string
  description = "Name of the resource group location"
  default     = "austriaeast"
}

variable "vnet_address_space" {
  type        = string
  description = "IP address spaces of vnet"
  default     = "10.0.0.0/16"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "List of subnet address prefixes"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Three-Tier-Application"
    ManagedBy   = "Terraform"
  }
}

variable "db_admin_user" {
  type        = string
  description = "Database admin user"
  default     = "pgadmin_dev"
}
