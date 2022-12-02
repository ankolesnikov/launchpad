terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.11.0"
    }
  }
}

provider "google" {
  credentials = var.gcp_service_credential

  project = var.project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

data "google_compute_zones" "available" {
}

# If the zone is not specified, use the first zone from the available zones
locals {
  zone = var.gcp_zone != "" ? var.gcp_zone : data.google_compute_zones.available.names[0]
}

module "vpc" {
  source       = "./modules/vpc"
  project_id   = var.project_id
  cluster_name = var.cluster_name
  host_cidr    = var.vpc_cidr
  gcp_region   = var.gcp_region
  vpc_mtu      = var.vpc_mtu
}

module "common" {
  source       = "./modules/common"
  project_id   = var.project_id
  cluster_name = var.cluster_name
  vpc_name     = module.vpc.vpc_name
}

module "managers" {
  source                = "./modules/manager"
  manager_count         = var.manager_count
  gcp_region            = var.gcp_region
  gcp_zone              = local.zone
  cluster_name          = var.cluster_name
  image_name            = module.common.image_name
  vpc_name              = module.vpc.vpc_name
  subnetwork_name       = module.vpc.subnet_name
  ssh_key               = module.common.ssh_key
  service_account_email = module.common.service_account_email
}

module "msrs" {
  source          = "./modules/msr"
  msr_count       = var.msr_count
  gcp_region      = var.gcp_region
  gcp_zone        = local.zone
  cluster_name    = var.cluster_name
  image_name      = module.common.image_name
  vpc_name        = module.vpc.vpc_name
  subnetwork_name = module.vpc.subnet_name
  ssh_key         = module.common.ssh_key
}

module "workers" {
  source                = "./modules/worker"
  worker_count          = var.worker_count
  gcp_region            = var.gcp_region
  gcp_zone              = local.zone
  cluster_name          = var.cluster_name
  vpc_name              = module.vpc.vpc_name
  subnetwork_name       = module.vpc.subnet_name
  image_name            = module.common.image_name
  ssh_key               = module.common.ssh_key
  worker_type           = var.worker_type
  service_account_email = module.common.service_account_email
}

module "windows_workers" {
  source                = "./modules/windows_worker"
  worker_count          = var.windows_worker_count
  gcp_zone              = local.zone
  cluster_name          = var.cluster_name
  vpc_name              = module.vpc.vpc_name
  subnetwork_name       = module.vpc.subnet_name
  image_name            = module.common.windows_2019_image_name
  ssh_key               = module.common.ssh_key
  worker_type           = var.worker_type
  windows_user          = var.windows_user
  windows_password      = var.windows_password
  service_account_email = module.common.service_account_email
}

locals {
  managers = [
    for host in module.managers.machines : {
      ssh = {
        address = host.network_interface.0.access_config.0.nat_ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.metadata["role"]
      privateInterface = "ens4"
    }
  ]

  msrs = [
    for host in module.msrs.machines : {
      ssh = {
        address = host.network_interface.0.access_config.0.nat_ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.metadata["role"]
      privateInterface = "ens4"
    }
  ]

  workers = [
    for host in module.workers.machines : {
      ssh = {
        address = host.network_interface.0.access_config.0.nat_ip
        user    = "ubuntu"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.metadata["role"]
      privateInterface = "ens4"
    }
  ]

  windows_workers = [
    for host in module.windows_workers.machines : {
      winRM = {
        address  = host.network_interface.0.access_config.0.nat_ip
        user     = var.windows_user
        password = var.windows_password
        useHTTPS = true
        insecure = true
      }
      role             = host.metadata["role"]
      privateInterface = "Ethernet"
    }
  ]

  mke_launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke"
    spec = {
      mke = {
        version       = var.mke_version
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${module.managers.lb_public_ip_address}",
        ]
      }
      msr   = {}
      hosts = concat(local.managers, local.msrs, local.workers, local.windows_workers)
    }
  }

  msr_launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke+msr"
    spec = {
      mke = {
        version       = var.mke_version
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${module.managers.lb_public_ip_address}",
        ]
      }
      msr = {
        installFlags : [
          "--ucp-insecure-tls",
          "--dtr-external-url ${module.msrs.lb_public_ip_address}",
        ]
      }
      hosts = concat(local.managers, local.msrs, local.workers, local.windows_workers)
    }
  }

  launchpad_tmpl = var.msr_count > 0 ? local.msr_launchpad_tmpl : local.mke_launchpad_tmpl
}


output "mke_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}
