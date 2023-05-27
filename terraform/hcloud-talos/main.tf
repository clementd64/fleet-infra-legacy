terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.6.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.38.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

locals {
  # Domain name hardcoded since cloudflare provider is hardcoded
  domain_name               = "oci.sh"
  nodes_private_ipv4_subnet = cidrsubnet(var.pods_subnet_ipv4, 8, 0)

  nodesets = { for n in var.nodes : n.id => n }

  # Split it from nodesets because ipv6 creation require nodesets to be defined
  nodesets_ip = { for n in var.nodes : n.id => merge(n, {
    ipv6_address         = cidrhost(hcloud_primary_ip.ipv6[n.id].ip_network, 1)
    ipv6_pod_cidr        = cidrsubnet(hcloud_primary_ip.ipv6[n.id].ip_network, 52, 1), # 116 - 64 = 52
    ipv4_private_address = cidrhost(local.nodes_private_ipv4_subnet, n.id)
    ipv4_pod_cidr        = cidrsubnet(var.pods_subnet_ipv4, 8, n.id)
  }) }
}

data "cloudflare_zone" "zone" {
  name = local.domain_name
}

data "hcloud_datacenter" "datacenter" {
  name = var.datacenter
}

data "hcloud_location" "location" {
  name = data.hcloud_datacenter.datacenter.location.name
}

# Generate dummy SSH key
# It is not used by Talos but avoid Hetzner to send an email with a password
resource "tls_private_key" "dummy_sshkey" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "dummy_sshkey" {
  name       = "${var.cluster_name} dummy SSH key"
  public_key = tls_private_key.dummy_sshkey.public_key_openssh

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

# Generate random ULA prefix for services CIDR
resource "random_id" "services_subnet" {
  byte_length = 7
}

locals {
  # Generate a /112 prefix. Maximum usable size by Kubernetes, even if up to /108 is accepted.
  # https://github.com/kubernetes/kubernetes/blob/v1.27.1/cmd/kubeadm/app/constants/constants.go#L233
  services_subnet_ipv6 = "fd${substr(random_id.services_subnet.hex, 0, 2)}:${substr(random_id.services_subnet.hex, 2, 4)}:${substr(random_id.services_subnet.hex, 6, 4)}:${substr(random_id.services_subnet.hex, 10, 4)}::/112"
}
