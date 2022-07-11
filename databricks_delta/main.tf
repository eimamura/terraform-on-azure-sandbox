terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.10.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.26.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.0.1"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = "westus2"
}

variable "mysecret" {
  type        = string
  description = "(optional) describe your variable"
}
