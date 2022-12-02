output "image_name" {
  value = data.google_compute_image.ubuntu.name
}

output "windows_2019_image_name" {
  value = data.google_compute_image.windows_2019.name
}

output "ssh_key" {
  value = tls_private_key.ssh_key
}

output "service_account_email" {
  value = google_service_account.default.email
}
