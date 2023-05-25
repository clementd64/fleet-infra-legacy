resource "hcloud_network" "network" {
  name     = "${var.cluster_name}-network"
  ip_range = var.pods_subnet_ipv4
  # 10.X.0.0/24 used for Nodes subnet
  # 10.X.{1..253}.0/24 used for Pods subnet
  # Nodes with id Y will have IP 10.X.0.Y and Pods subnet 10.X.Y.0/24

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

resource "hcloud_network_subnet" "node_subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = data.hcloud_location.location.network_zone
  ip_range     = cidrsubnet(hcloud_network.network.ip_range, 8, 0)
}

resource "hcloud_network_route" "pod_subnet" {
  for_each = local.nodesets

  network_id  = hcloud_network.network.id
  destination = cidrsubnet(hcloud_network.network.ip_range, 8, each.value.id)
  gateway     = cidrhost(hcloud_network_subnet.node_subnet.ip_range, each.value.id)
}

resource "hcloud_server_network" "network" {
  for_each   = local.nodesets
  server_id  = hcloud_server.node[each.key].id
  network_id = hcloud_network.network.id
  ip         = cidrhost(hcloud_network_subnet.node_subnet.ip_range, each.value.id)
}
