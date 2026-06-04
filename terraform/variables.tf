variable "location" {
  type        = string
  description = "Azure region where resources will be deployed."
  default     = "eastus"
}

variable "prefix" {
  type        = string
  description = "Prefix for resources"
  default     = "r365-finops"
}

variable "publisher_name" {
  type        = string
  description = "The name of publisher/company."
  default     = "Restaurant365 Platform Engineering"
}

variable "publisher_email" {
  type        = string
  description = "The email of publisher/company."
  default     = "platform@restaurant365.com"
}
