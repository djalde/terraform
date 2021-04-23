# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }

}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "virt-ifpb" {
  name     = "virt-ifpb"
  location = "eastus"
  tags = {
     Environment = "Terraform Virtualização IFPB"
     Team = "Redes de Computadores"
     }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "virtualNetwork1"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.virt-ifpb.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "mysub" {
  name                 = "minha-subrede"
  resource_group_name  = azurerm_resource_group.virt-ifpb.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name = "meuip"
  location = "eastus"
  resource_group_name  = azurerm_resource_group.virt-ifpb.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "meugrupodeseguranca"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.virt-ifpb.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "minha-nic"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.virt-ifpb.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mysub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "minha-vm"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.virt-ifpb.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on = [azurerm_virtual_machine.vm]
}
