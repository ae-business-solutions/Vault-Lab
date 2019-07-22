# 1. Install Azure CLI: https://aka.ms/installazurecliwindows
# 2. PS> az login
# 3. PS> az account list
# 4. PS> az account set --subscription="SUBSCRIPTION_ID"
provider "azurerm" {
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  location            = "${var.location}"
  address_space       = ["${var.vnet_address_space}"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
  name                      = "${var.subnet_name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  resource_group_name       = "${var.resource_group_name}"
  address_prefix            = "${var.subnet_address_prefix}"
}

resource "azurerm_network_security_group" "security_group" {
  name                = "${var.security_group_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_network_security_rule" "security_rule_ssh" {
  name                        = "ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.security_group.name}"
}

resource "azurerm_subnet_network_security_group_association" "security_group_association" {
  subnet_id                 = "${azurerm_subnet.subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.security_group.id}"
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.public_ip_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.resource_group_name}-ssh"
}

resource "azurerm_network_interface" "vnic0" {
  name                      = "${var.vnic_name}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.security_group.id}"

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.public_ip.id}"
  }
}

resource "azurerm_virtual_machine" "vault" {
  name                          = "${var.vm_name}"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  network_interface_ids         = ["${azurerm_network_interface.vnic0.id}"]
  vm_size                       = "Standard_DS1_v2"
  delete_os_disk_on_termination = true
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vault-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.vm_name}"
    admin_username = "${var.vm_user}"
    admin_password = "${var.vm_password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  identity = {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "vault_extension" {
  name                  = "vault-extension"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  virtual_machine_name  = "${azurerm_virtual_machine.vault.name}"
  publisher             = "Microsoft.OSTCExtensions"
  type                  = "CustomScriptForLinux"
  type_handler_version  = "1.2"

  settings              = <<SETTINGS
{
  "commandToExecute": "${var.deployment_command}",
  "fileUris": [
    "${var.deployment_script}"
  ]   
}
SETTINGS
}

data "azurerm_subscription" "primary" {}

resource "azurerm_role_assignment" "vault_role" {
  scope                = "${data.azurerm_subscription.primary.id}"
  role_definition_name = "Reader"
  principal_id         = "${lookup(azurerm_virtual_machine.vault.identity[0], "principal_id")}"
}