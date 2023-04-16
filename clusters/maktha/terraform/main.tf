terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.38.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.1.2"
    }
  }
}

variable "sshkey" {
  type = string
}

variable "image_amd64_id" {
  type = number
}

variable "image_arm64_id" {
  type = number
}

variable "endpoint_apikey" {
  type      = string
  sensitive = true
}

data "hcloud_datacenter" "datacenter" {
  name = local.datacenter
}

data "hcloud_location" "location" {
  name = data.hcloud_datacenter.datacenter.location.name
}

# SSH not used, but specified to avoid hetzner email
resource "hcloud_ssh_key" "sshkey" {
  name       = "default"
  public_key = var.sshkey

  labels = {
    "managed-by" = "terraform"
    "cluster"    = local.cluster_name
  }
}

resource "talos_machine_secrets" "secrets" {}

resource "talos_client_configuration" "talosconfig" {
  cluster_name    = local.cluster_name
  machine_secrets = talos_machine_secrets.secrets.machine_secrets
  endpoints       = [local.talos_endpoint]
}

# VIP assigned after bootstrapping
# Use the first controlplane for bootstrapping
locals {
  first_controlplane    = [for k, v in local.nodes : k if lookup(v, "is_controlplane", false)][0]
  first_controlplane_ip = "${hcloud_primary_ip.ipv6[local.first_controlplane].ip_address}1"
}
resource "talos_machine_bootstrap" "bootstrap" {
  talos_config = talos_client_configuration.talosconfig.talos_config
  endpoint     = local.first_controlplane_ip
  node         = local.first_controlplane_ip

  lifecycle {
    ignore_changes = [
      node,
      endpoint,
    ]
  }
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  talos_config = talos_client_configuration.talosconfig.talos_config
  endpoint     = local.talos_endpoint
  node         = local.talos_endpoint
}

output "talosconfig" {
  value       = talos_client_configuration.talosconfig.talos_config
  description = "Talosconfig for the cluster"
  sensitive   = true
}

output "kubeconfig" {
  value       = talos_cluster_kubeconfig.kubeconfig.kube_config
  description = "Kubeconfig for the cluster"
  sensitive   = true
}

output "load_balancer_ipv6" {
  value       = hcloud_load_balancer.load_balancer.ipv6
  description = "IPv6 address of the load balancer"
}

output "load_balancer_ipv4" {
  value       = hcloud_load_balancer.load_balancer.ipv4
  description = "IPv4 address of the load balancer"
}
