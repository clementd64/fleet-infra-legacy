resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.244.0.0/16"
  # 10.244.0.0/24 used for Nodes subnet
  # 10.244.{1..254}.0/24 used for Pods subnet
  # Nodes with id X will have IP 10.244.0.X and Pods subnet 10.244.X.0/24
}

resource "hcloud_network_subnet" "node_subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = "eu-central"
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
