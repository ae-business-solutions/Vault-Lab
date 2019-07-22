output "vault_public_ip" {
  description = "public IP address of the Vault server"
  value       = "${azurerm_public_ip.public_ip.ip_address}"
}

output "vault_private_ip" {
  description = "private IP address of the Vault server"
  value       = "${azurerm_network_interface.vnic0.private_ip_address}"
}