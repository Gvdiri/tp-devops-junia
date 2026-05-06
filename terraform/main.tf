provider "virtualbox" {}

# Déclaration des VMs
resource "virtualbox_vm" "vm" {
  name   = "${var.box_name}_${count.index}"
  image  = "https://vagrantcloud.com/generic/boxes/debian11/versions/4.3.12/providers/virtualbox/0/vagrant.box"
  count  = 2
  cpus   = 2
  memory = 2048
  network_adapter {
    type           = "bridged"
    host_interface = var.network_host_if
  }
}
