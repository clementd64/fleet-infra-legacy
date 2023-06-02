data "hcloud_image" "talos_arm" {
  with_selector     = "os=talos,version=v1.4.5"
  with_architecture = "arm"
}

module "hcloud_talos" {
  source = "../../../terraform/hcloud-talos"

  cluster_name       = "maktha"
  kubernetes_version = "v1.27.2"

  datacenter   = "fsn1-dc14"
  image_arm_id = data.hcloud_image.talos_arm.id

  api_floating_ipv6         = true
  api_floating_ip_api_token = var.api_floating_ip_api_token

  firewall      = true
  load_balancer = true

  allow_scheduling_on_control_planes = true

  nodes = [
    {
      id                   = 35
      instance_type        = "cax11"
      controlplane         = true
      placement_group      = "control-plane-1"
      load_balancer_target = true
    },
    {
      id                   = 115
      instance_type        = "cax11"
      controlplane         = true
      placement_group      = "control-plane-1"
      load_balancer_target = true
    },
    {
      id                   = 192
      instance_type        = "cax11"
      controlplane         = true
      placement_group      = "control-plane-1"
      load_balancer_target = true
    },
  ]
}
