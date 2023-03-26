locals {
  datacenter   = "fsn1-dc14"
  cluster_name = "maktha"

  pools = {
    #"pool_name" = {
    #  "ids" = [] # id of the node. Must be between 1 and 254 and unique across all pools
    #  "spec" = {
    #    "instance_type" = ""
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
        "is_controlplane" = true
      }
    }
  }

}
