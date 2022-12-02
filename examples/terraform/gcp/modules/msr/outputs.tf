output "lb_public_ip_address" {
  value = module.load_balancer_msr.external_ip
}

output "public_ips" {
  value = google_compute_instance.mke_msr.*.network_interface.0.access_config.0.nat_ip
}

output "private_ips" {
  value = google_compute_instance.mke_msr.*.network_interface.0.network_ip
}

output "machines" {
  value = google_compute_instance.mke_msr
}
