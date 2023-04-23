locals {
  datacenter   = "fsn1-dc14"
  cluster_name = "maktha"

  pools = {
    #"pool_name" = {
    #  "ids" = [] # id of the node. Must be between 1 and 253 and unique across all pools
    #  "spec" = {
    #    "instance_type" = ""
    #    "is_controlplane" = false
    #    "load_balancer_endpoint" = false # is pool used as load balancer endpoint
    #  }
    #}
    "control-plane-fb7n7" = {
      "ids" = [
        71,
        132,
        158,
      ]
      "spec" = {
        "instance_type"          = "cx21"
        "is_controlplane"        = true
        "load_balancer_endpoint" = true
      }
    }
  }
}
