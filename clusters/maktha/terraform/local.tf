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
    "control-plane1" = {
      "ids" = [
        41,
        171,
        220,
      ]
      "spec" = {
        "instance_type"          = "cax11"
        "is_controlplane"        = true
        "load_balancer_endpoint" = true
      }
    }
  }
}
