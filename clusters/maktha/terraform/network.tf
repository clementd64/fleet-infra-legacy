resource "hcloud_network" "network" {
  name     = "${local.cluster_name}-network"
  ip_range = "10.244.0.0/16"
  # 10.244.0.0/24 used for Nodes subnet
  # 10.244.{1..253}.0/24 used for Pods subnet
  # Nodes with id X will have IP 10.244.0.X and Pods subnet 10.244.X.0/24

  labels = {
    "managed-by" = "terraform"
    "cluster"    = local.cluster_name
  }
}

resource "hcloud_network_subnet" "node_subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = data.hcloud_location.location.network_zone
  ip_range     = "10.244.0.0/24"
}

resource "hcloud_network_route" "pod_subnet" {
  for_each = local.nodes

  network_id  = hcloud_network.network.id
  destination = cidrsubnet("10.244.0.0/16", 8, each.value.id)
  gateway     = cidrhost("10.244.0.0/24", each.value.id)
}

resource "hcloud_server_network" "network" {
  for_each   = local.nodes
  server_id  = hcloud_server.node[each.key].id
  network_id = hcloud_network.network.id
  ip         = cidrhost("10.244.0.0/24", each.value.id)
}

resource "hcloud_load_balancer" "load_balancer" {
  name = "${local.cluster_name}-lb"

  load_balancer_type = "lb11"
  location           = data.hcloud_location.location.name

  algorithm {
    type = "round_robin"
  }

  labels = {
    "managed-by" = "terraform"
    "cluster"    = local.cluster_name
  }
}

resource "hcloud_load_balancer_network" "network" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  network_id       = hcloud_network.network.id
  ip               = cidrhost("10.244.0.0/24", 254)
}

resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 32080
  proxyprotocol    = true
}

resource "hcloud_load_balancer_service" "https" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 32443
  proxyprotocol    = true
}

resource "hcloud_load_balancer_target" "nodepool" {
  for_each = { for k, v in local.nodes : k => v if lookup(v, "load_balancer_endpoint", false) }

  load_balancer_id = hcloud_load_balancer.load_balancer.id
  type             = "server"
  server_id        = hcloud_server.node[each.key].id
  use_private_ip   = true

  depends_on = [
    # Load balancer must be attached to network before
    hcloud_load_balancer_network.network
  ]
}
