resource "talos_machine_secrets" "secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.secrets.client_configuration
  endpoints            = [for n in var.nodes : cidrhost(hcloud_primary_ip.ipv6[n.id].ip_network, 1)]
}

data "talos_machine_configuration" "node" {
  for_each = local.nodesets

  cluster_name       = var.cluster_name
  cluster_endpoint   = local.kube_endpoint
  machine_secrets    = talos_machine_secrets.secrets.machine_secrets
  machine_type       = each.value.controlplane ? "controlplane" : "worker"
  kubernetes_version = var.kubernetes_version

  # TODO: disk encryption

  config_patches = [for c in flatten([
    # Sign API cert with k8s api domain
    { machine = { certSANs = [local.kube_endpoint_domain] } },
    # Set cluster DNS on worker node
    each.value.controlplane ? null : {
      machine = {
        kubelet = {
          clusterDNS = [
            # Cluster DNS is always the 10th service IP.
            # https://github.com/kubernetes/kubernetes/blob/v1.27.1/cmd/kubeadm/app/constants/constants.go#L645
            cidrhost(local.services_subnet_ipv6, 10),
            cidrhost(var.services_subnet_ipv4, 10),
          ]
        }
      }
    },
    # Control plane config
    !each.value.controlplane ? null : {
      cluster = {
        # Disable control-plane level cidr allocation.
        # Allocation will be handled by terraform
        controllerManager = {
          extraArgs = {
            allocate-node-cidrs = false
          }
        }

        network = {
          serviceSubnets = [
            local.services_subnet_ipv6,
            var.services_subnet_ipv4,
          ]
          # Disable default flannel
          cni = {
            name = "none"
          }
        }

        # Cilium set as kube proxy replacement
        proxy = {
          disabled = true
        }

        # Install Cilium
        inlineManifests = [
          {
            name     = "cilium"
            contents = local.cilium_manifest
          }
        ]

        allowSchedulingOnControlPlanes = var.allow_scheduling_on_control_planes

        # Exclude namespace from pod security
        apiServer = {
          admissionControl = [{
            name = "PodSecurity"
            configuration = {
              apiVersion = "pod-security.admission.config.k8s.io/v1alpha1"
              kind       = "PodSecurityConfiguration"
              exemptions = {
                namespaces = distinct(concat(
                  var.cilium_namespace != "kube-system" ? [var.cilium_namespace] : [],
                  var.pod_security_namespace_exemptions,
                ))
              }
            }
          }]
        }
      }
    },
    # API floating IP
    !(var.api_floating_ipv6 && each.value.controlplane) ? null : {
      machine = {
        network = {
          interfaces = [{
            interface = "eth0"
            vip = {
              ip = local.api_floating_ipv6
              hcloud = {
                apiToken = var.api_floating_ip_api_token
              }
            }
          }]
        }
      }
    },
    var.talos_custom_config,
    each.value.controlplane ? var.talos_custom_control_plane_config : var.talos_custom_worker_config,
    each.value.talos_custom_config,
  ]) : yamlencode(c)]
}

resource "talos_machine_configuration_apply" "config_apply" {
  for_each = local.nodesets

  client_configuration        = data.talos_client_configuration.talosconfig.client_configuration
  machine_configuration_input = data.talos_machine_configuration.node[each.key].machine_configuration

  endpoint = cidrhost(hcloud_primary_ip.ipv6[each.key].ip_network, 1)
  node     = cidrhost(hcloud_primary_ip.ipv6[each.key].ip_network, 1)

  depends_on = [
    hcloud_server.node,
  ]
}

# Floating ip assigned after bootstrapping
# Use the first controlplane for bootstrapping
locals {
  first_controlplane    = [for n in var.nodes : n if n.controlplane][0]
  first_controlplane_ip = cidrhost(hcloud_primary_ip.ipv6[local.first_controlplane.id].ip_network, 1)
}
resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  endpoint             = local.first_controlplane_ip
  node                 = local.first_controlplane_ip

  lifecycle {
    ignore_changes = [
      endpoint,
      node,
    ]
  }
}

# Patch node resouces with assigned PodCIDRs
resource "null_resource" "node_pod_cidr" {
  for_each = local.nodesets

  provisioner "local-exec" {
    command     = <<-EOT
    until kubectl get node "$NODE_NAME" --kubeconfig <(echo "$K8S_CONFIG" | base64 --decode) 2>/dev/null; do
        sleep 1
    done
    kubectl patch node "$NODE_NAME" -p "$PATCH" --kubeconfig <(echo "$K8S_CONFIG" | base64 --decode)
    EOT
    interpreter = ["/bin/bash", "-c"]
    environment = {
      NODE_NAME = "${var.cluster_name}-${each.key}"
      PATCH = jsonencode({
        spec = {
          podCIDRs = [
            cidrsubnet(hcloud_primary_ip.ipv6[each.key].ip_network, 52, 1), # 116 - 64 = 52
            cidrsubnet(var.pods_subnet_ipv4, 8, each.value.id),
          ]
        }
      })
      K8S_CONFIG = base64encode(data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw)
    }
  }

  depends_on = [
    hcloud_server.node,
    talos_machine_bootstrap.bootstrap,
  ]
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  endpoint             = local.first_controlplane_ip
  node                 = local.first_controlplane_ip
  wait                 = true # Wait API Server to be up

  depends_on = [
    talos_machine_bootstrap.bootstrap,
  ]
}
