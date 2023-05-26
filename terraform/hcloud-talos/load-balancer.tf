resource "hcloud_load_balancer" "load_balancer" {
  count = var.load_balancer ? 1 : 0

  name = "${var.cluster_name}-lb"

  load_balancer_type = var.load_balancer_type
  location           = data.hcloud_location.location.name

  algorithm {
    type = "round_robin"
  }

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

resource "hcloud_load_balancer_network" "network" {
  count = var.load_balancer ? 1 : 0

  load_balancer_id = hcloud_load_balancer.load_balancer[0].id
  network_id       = hcloud_network.network.id
  ip               = cidrhost(local.nodes_private_ipv4_subnet, 254)
}

resource "hcloud_load_balancer_service" "http" {
  count = var.load_balancer ? 1 : 0

  load_balancer_id = hcloud_load_balancer.load_balancer[0].id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 32080
  proxyprotocol    = true
}

resource "hcloud_load_balancer_service" "https" {
  count = var.load_balancer ? 1 : 0

  load_balancer_id = hcloud_load_balancer.load_balancer[0].id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 32443
  proxyprotocol    = true
}

resource "hcloud_load_balancer_target" "node" {
  for_each = { for k, v in local.nodesets : k => v if lookup(v, "load_balancer_target", false) }

  load_balancer_id = hcloud_load_balancer.load_balancer[0].id
  type             = "server"
  server_id        = hcloud_server.node[each.key].id
  use_private_ip   = true

  depends_on = [
    # Must be attached to network before
    hcloud_load_balancer_network.network,
    hcloud_server_network.network,
  ]
}

resource "cloudflare_record" "lb_ipv6" {
  count = var.load_balancer ? 1 : 0

  zone_id = data.cloudflare_zone.zone.id
  name    = "lb.${var.cluster_name}.k8s"
  type    = "AAAA"
  value   = hcloud_load_balancer.load_balancer[0].ipv6
  proxied = false
}

resource "cloudflare_record" "lb_ipv4" {
  count = var.load_balancer ? 1 : 0

  zone_id = data.cloudflare_zone.zone.id
  name    = "lb.${var.cluster_name}.k8s"
  type    = "A"
  value   = hcloud_load_balancer.load_balancer[0].ipv4
  proxied = false
}
