terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
  }
  
  # Backend configuration for Azure DevOps / Azure Storage Account
  # backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
