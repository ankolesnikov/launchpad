resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "ssh_public_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "ssh_keys/${var.cluster_name}.pem"
  provisioner "local-exec" {
    command = "chmod 0600 ${local_file.ssh_public_key.filename}"
  }
}


data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

data "google_compute_image" "windows_2019" {
  family  = "windows-2019-core"
  project = "windows-cloud"
}

resource "google_service_account" "default" {
  account_id   = "${var.cluster_name}-service-account-id"
  display_name = "Service Account"
}

resource "google_project_iam_member" "default" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.default.email}"
  role    = "roles/compute.admin"
}

resource "google_compute_firewall" "common_internal" {
  name        = "${var.cluster_name}-internal"
  description = "mke cluster common rule to allow all internal traffic"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "all"
  }

  target_tags = ["allow-internal"]
  source_tags = ["allow-internal"]
}

resource "google_compute_firewall" "common_ssh" {
  name        = "${var.cluster_name}-ssh"
  description = "mke cluster common rule"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["allow-ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "common_all_egress" {
  name        = "${var.cluster_name}-all-egress"
  description = "mke cluster common rule"
  network     = var.vpc_name
  direction   = "EGRESS"
  allow {
    protocol = "all"
  }
  destination_ranges = ["0.0.0.0/0"]
}
