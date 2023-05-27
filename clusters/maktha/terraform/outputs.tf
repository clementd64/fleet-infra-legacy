output "talosconfig" {
  value     = module.hcloud_talos.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.hcloud_talos.kubeconfig.config_file
  sensitive = true
}
