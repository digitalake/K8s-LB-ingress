output "node-ips" {
  value = { for k, vm_instance in google_compute_instance.vm_instance : k => vm_instance.network_interface[*].access_config[*].nat_ip }
}