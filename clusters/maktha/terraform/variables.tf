variable "api_floating_ip_api_token" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "fleet_infra_webhook_url" {
  type      = string
  sensitive = true
}

variable "fleet_infra_webhook_secret" {
  type      = string
  sensitive = true
}
