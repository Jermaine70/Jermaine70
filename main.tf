terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "jj-rg" {
  name     = "jj-resources"
  location = "West Europe"
  tags = {
    environments = "dev"
  }
}


resource "azurerm_virtual_network" "jj-vm" {
  name                = "jj-network"
  resource_group_name = azurerm_resource_group.jj-rg.name
  location            = azurerm_resource_group.jj-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    evironment = "dev"
  }

}

resource "azurerm_subnet" "jj-subnet" {
  name                 = "jj-subnet"
  resource_group_name  = azurerm_resource_group.jj-rg.name
  virtual_network_name = azurerm_virtual_network.jj-vm.name
  address_prefixes     = ["10.123.1.0/24"]

}
resource "azurerm_network_security_group" "jj-sg" {
  name                = "jj-sg"
  location            = azurerm_resource_group.jj-rg.location
  resource_group_name = azurerm_resource_group.jj-rg.name

  tags = {
    evironment = "dev"
  }

}

resource "azurerm_network_security_rule" "jj-dev-rule" {
  name                        = "jj-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.jj-rg.name
  network_security_group_name = azurerm_network_security_group.jj-sg.name

}

resource "azurerm_subnet_network_security_group_association" "jj-sga" {
  subnet_id                 = azurerm_subnet.jj-subnet.id
  network_security_group_id = azurerm_network_security_group.jj-sg.id
}


resource "azurerm_public_ip" "jj-ip" {
  name                = "jj-ip"
  resource_group_name = azurerm_resource_group.jj-rg.name
  location            = azurerm_resource_group.jj-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "jj-nic" {
  name                = "jj-nic"
  location            = azurerm_resource_group.jj-rg.location
  resource_group_name = azurerm_resource_group.jj-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jj-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jj-ip.id
  }

  tags = {
    environment = "dev"
  }
}


resource "azurerm_linux_virtual_machine" "jj-vm" {
  name                  = "jj-vm"
  resource_group_name   = azurerm_resource_group.jj-rg.name
  location              = azurerm_resource_group.jj-rg.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.jj-nic.id, ]


  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/jjazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-lts"
    version   = "latest"
  }

  tags = {
    environment = "dev"
  }
}
