# Bootstrapping MKE cluster on GCP

This directory provides an example flow for using Mirantis Launchpad with Terraform and GCP.

## Prerequisites

* An account and credentials for GCP.
* Terraform [installed](https://learn.hashicorp.com/terraform/getting-started/install)

## Authentication

The Terraform `google` provider uses JSON key file for authentication. Download the JSON key file for a service account and place it in a secure location on your workstation.
See [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials) for more information.

The authentication credentials can be passed to `google` provider in two ways:
* Setting environment variable GOOGLE_APPLICATION_CREDENTIALS with JSON key location.
* Setting `gcp_service_credential` variable in `terraform.tfvars` file. 

## Steps

1. Create terraform.tfvars file with needed details. You can use the provided terraform.tfvars.example as a baseline.
2. `terraform init`
3. `terraform apply`
4. `terraform output --raw mke_cluster | launchpad apply --config -`

## Notes

1. Both RDP and WinRM ports are opened for Windows workers.
