variable "location" {
  default = "Central US"
}

variable "resource_group_name" {
  default = "vault"
}

variable "vnet_name" {
  default = "vault"
}

variable "vnet_address_space" {
  default = "10.0.0.0/8"
}

variable "subnet_name" {
  default = "vault"
}

variable "subnet_address_prefix" {
  default = "10.1.1.0/24"
}

variable "security_group_name" {
  default = "vault"
}

variable "vnic_name" {
  default = "vault-vnic0"
}

variable "public_ip_name" {
  default = "vault"
}

variable "vm_name" {
  default = "vault"
}

variable "vm_user" {
  default = "vaultuser"
}

variable "vm_password" {
  default = "vaultpassword"
}

variable "deployment_command" {
  description = "Command to be excuted by the custom script extension"
  default     = "sh vault-install.sh"
}

variable "deployment_script" {
  description = "Script to download which can be executed by the custom script extension"
  default     = "https://gist.githubusercontent.com/dplacek/c5d806695fb1ddba7a6c060a3d2cc473/raw/cb10b35011cef798413dddc05ede36ab024a458f/vault-install.sh"
}