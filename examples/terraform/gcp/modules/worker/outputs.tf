output "private_ips" {
  value = google_compute_instance.mke_worker.*.network_interface.0.network_ip
}

output "machines" {
  value = google_compute_instance.mke_worker
}
