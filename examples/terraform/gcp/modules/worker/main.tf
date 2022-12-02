resource "google_compute_instance" "mke_worker" {
  count = var.worker_count

  name         = "${var.cluster_name}-worker-${count.index + 1}"
  machine_type = var.worker_type
  zone         = var.gcp_zone

  metadata = tomap({
    "role"   = "worker"
    ssh-keys = "ubuntu:${var.ssh_key.public_key_openssh}"
  })

  boot_disk {
    initialize_params {
      image = var.image_name
      type  = var.worker_volume_type
      size  = var.worker_volume_size
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
    "allow-worker",
    "allow-internal"
  ]

  service_account {
    email = var.service_account_email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
