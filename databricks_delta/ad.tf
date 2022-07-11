
data "azuread_client_config" "current" {}

resource "azuread_application" "example" {
  display_name = "myexample"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "example" {
  application_id               = azuread_application.example.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_key_vault" "example" {
  name                        = "mykvdvfzdgfv"
  resource_group_name         = azurerm_resource_group.example.name
  location                    = azurerm_resource_group.example.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
  ]
  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
  storage_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

resource "azurerm_key_vault_secret" "adlsname" {
  name         = "adlsname"
  value        = azurerm_storage_account.example.name
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_key_vault_secret" "applicationid" {
  name         = "applicationid"
  value        = azuread_service_principal.example.application_id
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_key_vault_secret" "tenantid" {
  name         = "tenantid"
  value        = azuread_service_principal.example.application_tenant_id
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_key_vault_secret" "mysecret" {
  name         = "mysecret"
  value        = var.mysecret
  key_vault_id = azurerm_key_vault.example.id
}
