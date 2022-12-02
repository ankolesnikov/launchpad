resource "google_compute_forwarding_rule" "default" {
  project         = var.project
  name            = var.name
  region          = var.region
  ports           = var.service_ports
  backend_service = google_compute_region_backend_service.default.self_link
}

resource "google_compute_region_backend_service" "default" {
  name                  = "${var.name}-backend-service"
  project               = var.project
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"

  health_checks = [google_compute_region_health_check.default.self_link]

  backend {
    group = var.target_instance_group
  }
}

resource "google_compute_region_health_check" "default" {
  project = var.project
  name    = "${var.name}-hc"

  https_health_check {
    port = var.health_check_port
  }
}
