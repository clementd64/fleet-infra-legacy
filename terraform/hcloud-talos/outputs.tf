output "talosconfig" {
  description = "talosconfig of the cluster"
  value       = data.talos_client_configuration.talosconfig.talos_config
}

output "kubeconfig" {
  description = "kubeconfig of the cluster"
  value = {
    config_file        = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
    ca_certificate     = data.talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.ca_certificate
    client_certificate = data.talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_certificate
    client_key         = data.talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_key
    host               = data.talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.host
  }
}

output "domain" {
  value = {
    load_balancer = var.load_balancer ? "lb.${var.cluster_name}.k8s.${local.domain_name}" : null
    nodes         = "nodes.${var.cluster_name}.k8s.${local.domain_name}"
    api           = "api.${var.cluster_name}.k8s.${local.domain_name}"
  }
}

output "nodes" {
  value = { for n in local.nodesets_ip : n.id => merge(n, {
    server_id = hcloud_server.node[n.id].id
  }) }
}
