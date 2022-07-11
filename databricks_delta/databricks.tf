
resource "azurerm_databricks_workspace" "example" {
  name                = "databricks-test"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "trial"
}

output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.example.workspace_url}/"
}

// initialize provider at Azure account-level
provider "databricks" {
  # alias = "azure_account"
  host = azurerm_databricks_workspace.example.workspace_url
}

resource "databricks_service_principal" "sp" {
  provider       = databricks
  application_id = azurerm_key_vault_secret.applicationid.value
}

# provider "databricks" {
#   host = azurerm_databricks_workspace.example.workspace_url
# }

# data "databricks_group" "admins" {
#   display_name = "admins"
# }

# resource "databricks_user" "me" {
#   user_name    = "imamuraeriel@gmail.com"
#   display_name = "Test User"
# }

# resource "databricks_group_member" "i-am-admin" {
#   group_id  = data.databricks_group.admins.id
#   member_id = databricks_user.me.id
# }


data "databricks_current_user" "me" {
  depends_on = [azurerm_databricks_workspace.example]
}
data "databricks_spark_version" "latest" {
  depends_on = [azurerm_databricks_workspace.example]
}
data "databricks_node_type" "smallest" {
  local_disk = true
}

resource "databricks_notebook" "this" {
  path     = "${data.databricks_current_user.me.home}/Terraform"
  language = "PYTHON"
  content_base64 = base64encode(<<-EOT
    # created from ${abspath(path.module)}
    display(spark.range(10))
    EOT
  )
}

resource "databricks_cluster" "example" {
  cluster_name            = "terraform"
  idempotency_token       = "terraform"
  spark_version           = "10.4.x-scala2.12"
  driver_node_type_id     = "Standard_F4"
  node_type_id            = "Standard_F4"
  num_workers             = 1
  autotermination_minutes = 10
}

# resource "databricks_job" "this" {
#   name = "Terraform Demo (${data.databricks_current_user.me.alphanumeric})"

#   new_cluster {
#     num_workers   = 1
#     spark_version = data.databricks_spark_version.latest.id
#     node_type_id  = data.databricks_node_type.smallest.id
#   }

#   notebook_task {
#     notebook_path = databricks_notebook.this.path
#   }
# }

output "notebook_url" {
  value = databricks_notebook.this.url
}

# output "job_url" {
#   value = databricks_job.this.url
# }

resource "databricks_secret_scope" "app" {
  name                     = "myscope"
  initial_manage_principal = "users"

  keyvault_metadata {
    resource_id = azurerm_key_vault.example.id
    dns_name    = azurerm_key_vault.example.vault_uri
  }
}

# resource "databricks_secret" "publishing_api" {
#   key          = "publishing_api"
#   string_value = azurerm_key_vault_secret.example.value
#   scope        = databricks_secret_scope.app.id
# }

# resource "databricks_mount" "mount" {
#   name        = "bronze"
#   resource_id = azurerm_storage_container.bronze.id
#   abfs {
#     client_id              = azurerm_key_vault_secret.applicationid.value
#     client_secret_scope    = databricks_secret_scope.app.name
#     client_secret_key      = azurerm_key_vault_secret.mysecret.value
#     initialize_file_system = true
#   }
# }

locals {
  tenant_id    = azurerm_key_vault_secret.tenantid.value
  client_id    = azurerm_key_vault_secret.applicationid.value
  secret_scope = databricks_secret_scope.app.name
  secret_key   = azurerm_key_vault_secret.mysecret.value
  container    = azurerm_storage_container.bronze.name
  storage_acc  = azurerm_storage_account.example.name
}

# resource "databricks_mount" "this" {
#   name = "tf-abfss"

#   uri = "abfss://${local.container}@${local.storage_acc}.dfs.core.windows.net"
#   extra_configs = {
#     "fs.azure.account.auth.type" : "OAuth",
#     "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
#     "fs.azure.account.oauth2.client.id" : local.client_id,
#     "fs.azure.account.oauth2.client.secret" : "{{secrets/${local.secret_scope}/${local.secret_key}}}",
#     "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${local.tenant_id}/oauth2/token",
#     "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
#   }
# }

resource "databricks_mount" "this" {
  name       = local.container
  uri        = "abfss://${local.container}@${local.storage_acc}.dfs.core.windows.net"
  cluster_id = databricks_cluster.example.cluster_id
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : local.client_id,
    "fs.azure.account.oauth2.client.secret" : local.secret_key,
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${local.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }
}
