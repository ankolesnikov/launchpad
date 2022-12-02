resource "google_compute_firewall" "worker" {
  name        = "${var.cluster_name}-msr"
  description = "mke cluster msrs"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-msr", "allow-lb-service-msr"]
}

resource "google_compute_instance" "mke_msr" {
  count        = var.msr_count
  name         = "${var.cluster_name}-msr-${count.index + 1}"
  machine_type = var.msr_type
  zone         = var.gcp_zone

  metadata = tomap({
    "role"   = "msr"
    ssh-keys = "ubuntu:${var.ssh_key.public_key_openssh}"
  })

  boot_disk {
    initialize_params {
      image = var.image_name
      type  = var.msr_volume_type
      size  = var.msr_volume_size
    }
  }

  network_interface {
    network    = var.vpc_name
    subnetwork = var.subnetwork_name
    access_config {
    }
  }
  tags = [
    var.cluster_name,
    "allow-ssh",
    "allow-msr",
    "allow-internal"
  ]
}

resource "google_compute_instance_group" "default" {
  name        = "${var.cluster_name}-msr-group"
  description = "MSR nodes instances group"
  zone        = var.gcp_zone
  instances   = [for i in google_compute_instance.mke_msr : i.self_link]
}

module "load_balancer_msr" {
  source                = "../networklb"
  region                = var.gcp_region
  name                  = "${var.cluster_name}-msr-lb"
  service_ports         = [443]
  health_check_port     = 443
  network               = var.vpc_name
  target_instance_group = google_compute_instance_group.default.self_link
}
