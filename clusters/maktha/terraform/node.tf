locals {
  nodes = merge([
    for pool, spec in local.pools : {
      for id in spec.ids : "${pool}-${id}" => merge(
        spec.spec,
        {
          "id" : id
          "placement_group" : pool
        }
      )
    }
  ]...)

  # Talos is unable to set the VIP if its not ::0
  # Because the floating range is fully routed, no issue with the "Subnet-Router anycast" (RFC 4291 § 2.6.1)
  talos_endpoint = cidrhost(hcloud_floating_ip.endpoint.ip_network, 0)
  kube_endpoint  = "https://[${local.talos_endpoint}]:6443"
}

resource "hcloud_floating_ip" "endpoint" {
  type          = "ipv6"
  name          = "${local.cluster_name}-endpoint"
  home_location = split("-", local.datacenter)[0]
}

resource "hcloud_placement_group" "placement_group" {
  for_each = local.pools
  name     = each.key
  type     = "spread"
}

resource "hcloud_primary_ip" "ipv6" {
  for_each      = local.nodes
  name          = "${each.key}-v6"
  datacenter    = local.datacenter
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_primary_ip" "ipv4" {
  for_each      = local.nodes
  name          = "${each.key}-v4"
  datacenter    = local.datacenter
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_server" "node" {
  for_each           = local.nodes
  name               = each.key
  image              = var.snapshot_id
  server_type        = each.value.instance_type
  datacenter         = local.datacenter
  placement_group_id = hcloud_placement_group.placement_group[each.value.placement_group].id

  ssh_keys = [
    hcloud_ssh_key.sshkey.id
  ]

  public_net {
    ipv6 = hcloud_primary_ip.ipv6[each.key].id
    ipv4 = hcloud_primary_ip.ipv4[each.key].id
  }
}

resource "talos_machine_configuration_controlplane" "machineconfig" {
  cluster_name     = local.cluster_name
  cluster_endpoint = local.kube_endpoint
  machine_secrets  = talos_machine_secrets.secrets.machine_secrets

  config_patches = flatten([
    file("${path.module}/files/common.yaml"),
    templatefile("${path.module}/files/controlplane.yaml", {
      hcloud_vip    = local.talos_endpoint
      hcloud_apikey = var.endpoint_apikey
    }),
    [for k, v in local.nodes : templatefile("${path.module}/files/ippool.yaml", {
      name : k,
      ipv6Cidr : cidrsubnet("${hcloud_primary_ip.ipv6[k].ip_address}/64", 52, 1), # 116 - 64 = 52
      ipv4Cidr : cidrsubnet("10.244.0.0/16", 8, v.id)
    })]
  ])
}

resource "talos_machine_configuration_worker" "machineconfig" {
  cluster_name     = local.cluster_name
  cluster_endpoint = local.kube_endpoint
  machine_secrets  = talos_machine_secrets.secrets.machine_secrets
  config_patches = [
    file("${path.module}/files/common.yaml"),
    file("${path.module}/files/worker.yaml"),
  ]
}

resource "talos_machine_configuration_apply" "config_apply" {
  for_each     = local.nodes
  talos_config = talos_client_configuration.talosconfig.talos_config

  machine_configuration = each.value.is_controlplane ? talos_machine_configuration_controlplane.machineconfig.machine_config : talos_machine_configuration_worker.machineconfig.machine_config

  endpoint = "${hcloud_primary_ip.ipv6[each.key].ip_address}1"
  node     = "${hcloud_primary_ip.ipv6[each.key].ip_address}1"

  depends_on = [
    hcloud_server.node,
  ]
}
