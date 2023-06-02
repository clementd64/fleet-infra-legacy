data "hcloud_server_type" "instance_type" {
  for_each = toset([for n in var.nodes : n.instance_type])
  name     = each.value
}

resource "hcloud_placement_group" "placement_group" {
  for_each = toset([for n in var.nodes : n.placement_group if n.placement_group != null])
  name     = "${var.cluster_name}-${each.key}"
  type     = "spread"

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

resource "hcloud_primary_ip" "ipv6" {
  for_each = local.nodesets

  name          = "${var.cluster_name}-${each.key}-v6"
  datacenter    = var.datacenter
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

resource "hcloud_primary_ip" "ipv4" {
  for_each = local.nodesets

  name          = "${var.cluster_name}-${each.key}-v4"
  datacenter    = var.datacenter
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }
}

resource "hcloud_server" "node" {
  for_each = local.nodesets

  name               = "${var.cluster_name}-${each.key}"
  image              = data.hcloud_server_type.instance_type[each.value.instance_type].architecture == "arm" ? var.image_arm_id : var.image_x86_id
  server_type        = each.value.instance_type
  datacenter         = var.datacenter
  placement_group_id = each.value.placement_group == null ? null : hcloud_placement_group.placement_group[each.value.placement_group].id

  ssh_keys = [
    hcloud_ssh_key.dummy_sshkey.id
  ]

  public_net {
    ipv6 = hcloud_primary_ip.ipv6[each.key].id
    ipv4 = hcloud_primary_ip.ipv4[each.key].id
  }

  labels = {
    "managed-by" = "terraform"
    "cluster"    = var.cluster_name
  }

  lifecycle {
    ignore_changes = [
      image,
    ]
  }
}

resource "cloudflare_record" "node_ipv6" {
  for_each = local.nodesets_ip

  zone_id = data.cloudflare_zone.zone.id
  name    = "nodes.${var.cluster_name}.k8s"
  type    = "AAAA"
  value   = each.value.ipv6_address
  proxied = false
}

resource "cloudflare_record" "node_ipv4" {
  for_each = local.nodesets_ip

  zone_id = data.cloudflare_zone.zone.id
  name    = "nodes.${var.cluster_name}.k8s"
  type    = "A"
  value   = each.value.ipv4_address
  proxied = false
}

resource "hcloud_rdns" "node_ipv6" {
  for_each = local.nodesets_ip

  server_id  = hcloud_server.node[each.key].id
  ip_address = each.value.ipv6_address
  dns_ptr    = "${each.key}.nodes.${var.cluster_name}.k8s.${local.domain_name}"
}

resource "hcloud_rdns" "node_ipv4" {
  for_each = local.nodesets_ip

  server_id  = hcloud_server.node[each.key].id
  ip_address = each.value.ipv4_address
  dns_ptr    = "${each.key}.nodes.${var.cluster_name}.k8s.${local.domain_name}"
}
