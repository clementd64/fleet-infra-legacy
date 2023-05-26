resource "hcloud_floating_ip" "api" {
  count = var.api_floating_ipv6 ? 1 : 0

  type          = "ipv6"
  name          = "${var.cluster_name}-api"
  home_location = data.hcloud_location.location.name

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

locals {
  # Talos is unable to set the VIP if its not ::0
  # Because the floating range is fully routed, no issue with the "Subnet-Router anycast" (RFC 4291 § 2.6.1)
  api_floating_ipv6 = var.api_floating_ipv6 ? cidrhost(hcloud_floating_ip.api[0].ip_network, 0) : null
}

resource "cloudflare_record" "api_ipv6_floating_ip" {
  count = var.api_floating_ipv6 ? 1 : 0

  zone_id = data.cloudflare_zone.zone.id
  name    = "api.${var.cluster_name}.k8s"
  type    = "AAAA"
  value   = local.api_floating_ipv6
  proxied = false
}

resource "cloudflare_record" "api_ipv6_nodes" {
  for_each = (
    var.api_floating_ipv6
    ? {}
    : { for k, v in local.nodesets_ip : k => v if v.controlplane }
  )

  zone_id = data.cloudflare_zone.zone.id
  name    = "api.${var.cluster_name}.k8s"
  type    = "AAAA"
  value   = each.value.ipv6_address
  proxied = false
}

locals {
  kube_endpoint_domain = "api.${var.cluster_name}.k8s.${local.domain_name}"
  kube_endpoint        = "https://${local.kube_endpoint_domain}:6443"
}
