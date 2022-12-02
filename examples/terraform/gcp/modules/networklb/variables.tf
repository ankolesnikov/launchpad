variable "project" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = ""
}

variable "network" {
  type = string
}

variable "name" {
  type = string
}

variable "service_ports" {
  type        = list(number)
  description = "List of TCP port your service is listening on."
}


variable "health_check_port" {
  type        = number
  description = "Health check port for the service"
}

variable "target_instance_group" {
  type        = string
  description = "Target instance group for the network load balancer"
}
