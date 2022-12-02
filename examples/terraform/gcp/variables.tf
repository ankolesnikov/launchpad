variable "project_id" {
  default = "orchestration-348616"
}

variable "cluster_name" {
  default = "mke"
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_zone" {
  default = "us-central1-a"
}

variable "gcp_service_credential" {
  default = ""
}

variable "vpc_mtu" {
  default     = 1500
  description = "MTU for the VPC. GCP support two MTU values for the VPC: 1460 or 1500"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "admin_password" {
  default = "dockeradmin"
}

variable "manager_count" {
  default = 1
}

variable "worker_count" {
  default = 3
}

variable "windows_worker_count" {
  default = 0
}

variable "msr_count" {
  default = 0
}

variable "manager_type" {
  default = "e2-standard-4"
}

variable "worker_type" {
  default = "e2-standard-4"
}

variable "msr_type" {
  default = "e2-standard-4"
}

variable "manager_volume_type" {
  default = "pd-balanced"
}

variable "manager_volume_size" {
  default = 100
}

variable "worker_volume_size" {
  default = 100
}

variable "msr_volume_size" {
  default = 100
}

variable "windows_user" {
  default = "winadmin"
}

variable "windows_password" {
  default = "w!ndozePassw0rd"
}

variable "mke_version" {
  default = "3.5.5"
}
