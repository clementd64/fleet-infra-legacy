variable "cluster_name" {
  description = "Name of the cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9\\-]{1,63}$", var.cluster_name))
    error_message = "The cluster name must be a RFC 1123 DNS Label"
  }
}

variable "datacenter" {
  description = "Datacenter name which cluster will be deployed in"
  type        = string
}

variable "image_x86_id" {
  description = "Snapshot ID of talos x86 image"
  type        = number
  default     = null
}

variable "image_arm_id" {
  description = "Snapshot ID of talos arm image"
  type        = number
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to install when bootstrapping"
  type        = string
  default     = null
}

# No node pool is handled. This allow fine grained role, type and placement_group definition.
variable "nodes" {
  description = "Cluster's nodes"
  type = list(object({
    id                   = number
    instance_type        = string
    placement_group      = optional(string)
    controlplane         = optional(bool, false)
    load_balancer_target = optional(bool, false)
    talos_custom_config  = optional(any)
  }))

  validation {
    condition     = length(var.nodes) > 0
    error_message = "At least one node must be defined"
  }

  validation {
    condition     = anytrue([for n in var.nodes : n.controlplane])
    error_message = "At least one control plane node must be defined"
  }
}

variable "talos_custom_config" {
  description = "Custom config to apply"
  type        = any
  default     = null
}

variable "talos_custom_control_plane_config" {
  description = "Custom config to apply to control plane node"
  type        = any
  default     = null
}

variable "talos_custom_worker_config" {
  description = "Custom config to apply to worker node"
  type        = any
  default     = null
}

variable "api_floating_ipv6" {
  description = "Use floating ipv6 as API endpoint"
  type        = bool
  default     = false
}

variable "api_floating_ip_api_token" {
  description = "API token used for API floating IP assignment and failover"
  type        = string
  default     = null
}

variable "pods_subnet_ipv4" {
  description = "IPv4 service subnet to use"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.pods_subnet_ipv4))
    error_message = "Subnet must be a valid IPv4 CIDR"
  }

  validation {
    condition     = endswith(var.pods_subnet_ipv4, "/16")
    error_message = "Subnet must use /16 mask"
  }
}

variable "services_subnet_ipv4" {
  description = "IPv4 service subnet to use"
  type        = string
  # Default to /16 to align with IPv6 limitation.
  default = "10.96.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.services_subnet_ipv4))
    error_message = "Subnet must be a valid IPv4 CIDR"
  }
}

variable "load_balancer" {
  description = "Add a load balancer"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Load balancer type"
  type        = string
  default     = "lb11"
}

variable "load_balancer_target_http_port" {
  description = "Load balancer target's HTTP port"
  type        = number
  default     = 32080
}

variable "load_balancer_target_https_port" {
  description = "Load balancer target's HTTPS port"
  type        = number
  default     = 32443
}

variable "firewall" {
  description = "Enable basic firewalling"
  type        = bool
  default     = false
}

variable "cilium_version" {
  description = "Cilium version to install"
  type        = string
  default     = "v1.13.3"
}

variable "cilium_namespace" {
  description = "Namespace cilium will use"
  type        = string
  default     = "cilium-system"
}

variable "cilium_custom_values" {
  description = "Custom value to pass to cilium helm chart"
  type        = any
  default     = {}
}

variable "allow_scheduling_on_control_planes" {
  description = "Allow scheduling on control plane"
  type        = bool
  default     = false
}

variable "pod_security_namespace_exemptions" {
  description = "Namespace list to exempt of security enforcement"
  type        = list(string)
  default     = []
}

variable "talos_bootstrap_node_index" {
  description = "Change node used for bootstrapping and fetching kubeconfig. Useful if selected node is failed."
  type        = number
  default     = 1
}
