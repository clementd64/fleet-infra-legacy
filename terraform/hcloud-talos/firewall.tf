resource "hcloud_firewall" "firewall" {
  count = var.firewall ? 1 : 0

  name = "${var.cluster_name}-firewall"

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }

  rule {
    description = "Allow ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
  }

  rule {
    description = "Allow Talos API"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
  }

  rule {
    description = "Allow Kubernetes API"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
  }

  rule {
    description = "Allow node to node internal IPv6 traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "any"
    source_ips  = [for _, v in local.nodesets : hcloud_primary_ip.ipv6[v.id].ip_network]
  }

  rule {
    description = "Allow node to node internal IPv6 traffic"
    direction   = "in"
    protocol    = "udp"
    port        = "any"
    source_ips  = [for _, v in local.nodesets : hcloud_primary_ip.ipv6[v.id].ip_network]
  }
}

resource "hcloud_firewall_attachment" "firewall" {
  count = var.firewall ? 1 : 0

  firewall_id = hcloud_firewall.firewall[0].id
  server_ids  = [for n in hcloud_server.node : n.id]
}