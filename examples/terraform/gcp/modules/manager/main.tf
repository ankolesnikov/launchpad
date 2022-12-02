data "google_client_openid_userinfo" "me" {}

resource "google_compute_firewall" "manager_internal" {
  name        = "${var.cluster_name}-managers-internal"
  description = "mke cluster managers nodes internal traffic"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["2379-2380"]
  }

  target_tags = ["allow-manager"]
  source_tags = ["allow-manager"]
}

resource "google_compute_firewall" "manager" {
  name        = "${var.cluster_name}-managers"
  description = "mke cluster managers ingress traffic"
  network     = var.vpc_name
  direction   = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["443", "6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-manager"]
}

resource "google_compute_instance" "mke_manager" {
  count        = var.manager_count
  name         = "${var.cluster_name}-manager-${count.index + 1}"
  machine_type = var.manager_type
  zone         = var.gcp_zone

  metadata = tomap({
    "role"   = "manager"
    ssh-keys = "ubuntu:${var.ssh_key.public_key_openssh}"
  })

  boot_disk {
    initialize_params {
      image = var.image_name
      type  = var.manager_volume_type
      size  = var.manager_volume_size
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
    "allow-manager",
    "allow-internal"
  ]

  service_account {
    email = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_compute_instance_group" "default" {
  name        = "${var.cluster_name}-manager-group"
  description = "Manager nodes instances group"
  zone        = var.gcp_zone
  instances   = [for i in google_compute_instance.mke_manager : i.self_link]

  named_port {
    name = "api"
    port = 443
  }

  named_port {
    name = "kubeapi"
    port = 6443
  }
}

module "load_balancer_manager" {
  source                = "../networklb"
  region                = var.gcp_region
  network               = var.vpc_name
  name                  = "${var.cluster_name}-manager-lb"
  service_ports         = [443, 6443]
  health_check_port     = 443
  target_instance_group = google_compute_instance_group.default.self_link
}
