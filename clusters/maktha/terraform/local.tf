locals {
  datacenter   = "fsn1-dc14"
  cluster_name = "maktha"

  pools = {
    #"pool_name" = {
    #  "suffixes" = [] # id appended to the pool name, allowing stable name and removal of nodes
    #  "spec" = {
    #    "instance_type" = ""
    #  }
    #}
    "control-plane" = {
      "suffixes" = [
        "aj2t4",
        "ggh3n",
        "s7qyt",
      ]
      "spec" = {
        "instance_type"   = "cx21"
        "is_controlplane" = true
      }
    }
  }

}
