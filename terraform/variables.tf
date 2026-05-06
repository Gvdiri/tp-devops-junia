variable "box_name" {
  description = "Nom de la VM"
  type        = string
  default     = "vm_devops"
}

variable "network_host_if" {
  description = "Nom de l'interface réseau hôte (adapter à votre machine)"
  type        = string
  default     = "Realtek RTL8852BE WiFi 6 802.11ax PCIe Adapter"
}
