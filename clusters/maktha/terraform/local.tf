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
    "control-plane1" = {
      "ids" = [
        41,
        171,
        220,
      ]
      "spec" = {
        "instance_type"   = "cax11"
        "image_id"        = var.image_arm64_id
        "is_controlplane" = true
      }
    }
  }
}
