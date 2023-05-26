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
  ip_range     = local.nodes_private_ipv4_subnet
}

resource "hcloud_network_route" "pod_subnet" {
  for_each = local.nodesets_ip

  network_id  = hcloud_network.network.id
  destination = each.value.ipv4_pod_cidr
  gateway     = each.value.ipv4_private_address
}

resource "hcloud_server_network" "network" {
  for_each   = local.nodesets_ip
  server_id  = hcloud_server.node[each.key].id
  network_id = hcloud_network.network.id
  ip         = each.value.ipv4_private_address
}
