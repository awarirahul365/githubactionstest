terraform {
  #required_version = ">=1.3.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.43.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "rahultestrg"
    storage_account_name = "rahulteststorage365"
    container_name = "terraformstatefile"
    key="tfrealiabilityalerting.tfstate"
    tenant_id = "42f7676c-f455-423c-82f6-dc2d99791af7"
    subscription_id = "b437f37b-b750-489e-bc55-43044286f6e1"
  }
}
provider "azurerm" {
  features {
  }
  skip_provider_registration = true
  subscription_id = "b437f37b-b750-489e-bc55-43044286f6e1"
}


variable "rg_alerting_name" {
  type = string
}

variable "rg_alerting_location" {
  type = string
  
}
variable "functionapp_alerting_name" {
  type = string
}

variable "functionapp_storage" {
  type = string
}

variable "functionapp_app_service" {
  type = string
}

variable "logicapp_app_service" {
  type = string
}

variable "logicapp_alerting_name" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_alerting_name
  location = var.rg_alerting_location
}

resource "azurerm_storage_account" "storagealerting" {
  name                     = var.functionapp_storage
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Add rules from particular network testing1
  allow_nested_items_to_be_public = false
}

resource "azurerm_app_service_plan" "appservicefunctionapp" {
  name                = var.functionapp_app_service
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "functionappalerting" {
  name                       = var.functionapp_alerting_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.appservicefunctionapp.id
  storage_account_name       = azurerm_storage_account.storagealerting.name
  storage_account_access_key = azurerm_storage_account.storagealerting.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  
  site_config {
    linux_fx_version = "python|3.11"
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME="python"
  }
}

resource "azurerm_app_service_plan" "logicappserviceplanalerting" {
  name                = var.logicapp_app_service
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "elastic"


  sku {
    tier = "WorkflowStandard"
    size = "WS1"
  }
}

resource "azurerm_logic_app_standard" "logicappalerting" {
  name                       = var.logicapp_alerting_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.logicappserviceplanalerting.id
  storage_account_name       = azurerm_storage_account.storagealerting.name
  storage_account_access_key = azurerm_storage_account.storagealerting.primary_access_key
  https_only = true
  version = "~4"

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
  }
  identity {
    type = "SystemAssigned"
  }

  
}

