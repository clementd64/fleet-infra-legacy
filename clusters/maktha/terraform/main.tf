terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.7.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.40.0"
    }
  }
}

provider "github" {
  token = var.github_token
}
