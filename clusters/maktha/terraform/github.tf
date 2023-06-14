resource "github_repository_deploy_key" "fleet-infra" {
  title      = "Flux maktha"
  repository = "fleet-infra"
  key        = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGINc2v1YVfuWo+36jVR6wUkJqGIMfHt6x7ekBgrkv2Z"
  read_only  = true
}

resource "github_repository_webhook" "fleet-infra" {
  repository = "fleet-infra"
  events     = ["push"]

  configuration {
    url          = var.fleet_infra_webhook_url
    content_type = "json"
    secret       = var.fleet_infra_webhook_secret
    insecure_ssl = false
  }
}
