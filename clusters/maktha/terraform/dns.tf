data "cloudflare_zone" "segfault-ovh" {
  name = "segfault.ovh"
}

resource "cloudflare_record" "lb_segfault-ovh" {
  for_each = toset([
    "outline",
  ])

  zone_id = data.cloudflare_zone.segfault-ovh.id
  name    = each.value
  type    = "CNAME"
  value   = module.hcloud_talos.domain.load_balancer
  proxied = false
}
