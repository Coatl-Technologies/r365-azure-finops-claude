resource "azurerm_resource_group" "finops_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Key Vault to securely store Anthropic API Key
resource "azurerm_key_vault" "kv" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.finops_rg.location
  resource_group_name         = azurerm_resource_group.finops_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
}

data "azurerm_client_config" "current" {}

# API Management as our Claude Gateway (FinOps enforcement layer)
resource "azurerm_api_management" "apim" {
  name                = "${var.prefix}-apim"
  location            = azurerm_resource_group.finops_rg.location
  resource_group_name = azurerm_resource_group.finops_rg.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  # Developer SKU is cost-effective for labs, Production uses Premium
  sku_name = "Developer_1"

  identity {
    type = "SystemAssigned"
  }
}

# Example API to proxy Claude Requests
resource "azurerm_api_management_api" "claude_api" {
  name                = "claude-ai-api"
  resource_group_name = azurerm_resource_group.finops_rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Claude AI Gateway API"
  path                = "claude"
  protocols           = ["https"]
  
  # Pointing directly to Anthropic API
  service_url = "https://api.anthropic.com"
}

# Attach the FinOps Rate Limiting policy
resource "azurerm_api_management_api_policy" "claude_finops_policy" {
  api_name            = azurerm_api_management_api.claude_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.finops_rg.name
  
  # Inject the XML policy file for Rate Limiting & Spend control
  xml_content = file("${path.module}/policies/apim-claude-policy.xml")
}
