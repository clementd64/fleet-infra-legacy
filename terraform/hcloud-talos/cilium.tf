data "helm_template" "cilium" {
  name       = "cilium"
  namespace  = var.cilium_namespace
  repository = "https://helm.cilium.io/"

  chart        = "cilium"
  version      = var.cilium_version
  include_crds = true

  values = [
    yamlencode({
      ipam = {
        mode = "kubernetes"
      }

      # kube proxy replacement
      kubeProxyReplacement = "strict"
      k8sServiceHost       = local.kube_endpoint_domain
      k8sServicePort       = 6443

      # IPv4 routed using private network
      tunnel                = "disabled"
      ipv4NativeRoutingCIDR = var.pods_subnet_ipv4
      MTU                   = 1450 # Hetzner private network use broken MTU

      # Set dual stack config
      ipv6                 = { enabled = true }
      enableIPv6Masquerade = false
      ipv4                 = { enabled = true }
      enableIPv4Masquerade = true
      bpf = {
        masquerade = true
      }

      # Talos run recent kernel
      enableXTSocketFallback = false

      # Talos specific
      # https://www.talos.dev/v1.4/kubernetes-guides/network/deploying-cilium/#method-2-helm-manifests-install
      securityContext = {
        capabilities = {
          ciliumAgent = [
            "CHOWN",
            "DAC_OVERRIDE",
            "FOWNER",
            "IPC_LOCK",
            "KILL",
            "NET_ADMIN",
            "NET_RAW",
            "SETGID",
            "SETUID",
            "SYS_ADMIN",
            "SYS_RESOURCE",
          ]
          cleanCiliumState = [
            "NET_ADMIN",
            "SYS_ADMIN",
            "SYS_RESOURCE",
          ]
        }
      }
      cgroup = {
        autoMount = { enabled = false }
        hostRoot  = "/sys/fs/cgroup"
      }
    }),
    yamlencode(var.cilium_custom_values)
  ]
}

locals {
  # Create namespace if needed
  cilium_manifest = var.cilium_namespace == "kube-system" ? data.helm_template.cilium.manifest : join("\n---\n", [
    yamlencode({
      apiVersion = "v1"
      kind       = "Namespace"
      metadata = {
        name = var.cilium_namespace
      }
    }),
    data.helm_template.cilium.manifest,
  ])
}
