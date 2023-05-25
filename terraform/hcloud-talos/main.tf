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

# TODO: Factorize cidrhost and cidrsubnet call

locals {
  # Domain name hardcoded since gandi provider is hardcoded
  domain_name = "oci.sh"

  nodesets = { for n in var.nodes : n.id => n }
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
  name       = "Dummy SSH Key"
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
