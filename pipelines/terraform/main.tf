resource "azurerm_resource_group" "rg" {
    name = "openlearning"
    location = "eastus"
}

provider "azurerm" {
    features {
        key_vault {
            purge_soft_delete_on_destroy    = true
            recover_soft_deleted_key_vaults = true
        }
    }
    subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = "openlearning-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "openlearning-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_container_registry" "acr" {
  name                = "openlearning"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "openlearning-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "openlearning"

  default_node_pool {
    name       = "olpool"
    node_count = 2
    vm_size    = "standard_d2pls_v6"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_key_vault" "vault" {
  name                        = "openlearning-keyvault"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
      "List"
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover",
      "List"
    ]
  }
}

# Adding a secret
resource "azurerm_key_vault_secret" "subscription_id" {
  name         = "azure-subscription-id"
  value        = var.subscription_id
  key_vault_id = azurerm_key_vault.vault.id
}