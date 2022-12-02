variable "gcp_region" {}

variable "gcp_zone" {}

variable "cluster_name" {}

variable "vpc_name" {}

variable "subnetwork_name" {}

variable "image_name" {}

variable "ssh_key" {}

variable "msr_count" {
  default = 3
}

variable "msr_type" {
  default = "e2-standard-4"
}

variable "msr_volume_type" {
  default = "pd-balanced"
}

variable "msr_volume_size" {
  default = 100
}
