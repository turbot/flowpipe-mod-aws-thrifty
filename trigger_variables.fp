// TODO: PLURALISE THE NAMES OF THE VARIABLES

// EC2
variable "ec2_application_load_balancer_unused_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_application_load_balancer_unused_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_classic_load_balancer_unused_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_classic_load_balancer_unused_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_gateway_load_balancer_unused_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_gateway_load_balancer_unused_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_instances_exceeding_max_age_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_instances_exceeding_max_age_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_instances_large_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_instances_large_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_instances_older_generation_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_instances_older_generation_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_instances_without_graviton_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_instances_without_graviton_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ec2_network_load_balancer_unused_trigger_enabled" {
  type    = bool
  default = false
}

variable "ec2_network_load_balancer_unused_trigger_schedule" {
  type    = string
  default = "15m"
}

