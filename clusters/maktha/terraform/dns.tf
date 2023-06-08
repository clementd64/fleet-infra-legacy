data "cloudflare_zone" "zone" {
  name = "segfault.ovh"
}

resource "cloudflare_record" "segfault-ovh" {
  zone_id = data.cloudflare_zone.zone.id
  name    = "@"
  type    = "CNAME"
  # TODO: pass as module output
  value   = "lb.maktha.k8s.oci.sh"
  proxied = false
}
