locals {
  datacenter   = "fsn1-dc14"
  cluster_name = "maktha"

  pools = {
    #"pool_name" = {
    #  "ids" = [] # id of the node. Must be between 1 and 254 and unique across all pools
    #  "spec" = {
    #    "instance_type" = ""
    #    "image_id" = 0
    #    "is_controlplane" = false
    #  }
    #}
    "control-plane" = {
      "ids" = [
        73,
        149,
        154,
      ]
      "spec" = {
        "instance_type"   = "cx21"
        "image_id"        = var.image_amd64_id
        "is_controlplane" = true
      }
    }
  }
}
