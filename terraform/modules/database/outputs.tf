output "postgresql_server_id" {
  description = "ID of postgresql server"
  value       = azurerm_postgresql_flexible_server.postgres.id
}

output "database_postgresql_server_id" {
  description = "ID of database postgreSQL server"
  value       = azurerm_postgresql_flexible_server_database.portfolio.id
}

output "postgres_fqdn" {
  description = "azurerm_postgresql_flexible_server.postgres.fqdn"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "database_portfolio_name" {
  description = "PostgreSQL flexible server portfolio database name"
  value       = azurerm_postgresql_flexible_server_database.portfolio.name
}

output "database_portfolio" {
  description = "PostgreSQL flexible server portfolio database name"
  value       = azurerm_postgresql_flexible_server_database.portfolio.id
}

output "database_password" {
  description = "Database password"
  value       = azurerm_postgresql_flexible_server.postgres.administrator_password
  sensitive   = true
}