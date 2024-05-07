// EBS
variable "ebs_snapshots_exceeding_max_age_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_snapshots_exceeding_max_age_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_attached_to_stopped_instances_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_attached_to_stopped_instances_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_large_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_large_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_unattached_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_unattached_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_using_gp2_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_using_gp2_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_using_io1_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_using_io1_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_with_high_iops_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_with_high_iops_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_with_low_iops_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_with_low_iops_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_with_low_usage_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_with_low_usage_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "ebs_volumes_without_attachments_trigger_enabled" {
  type    = bool
  default = false
}

variable "ebs_volumes_without_attachments_trigger_schedule" {
  type    = string
  default = "15m"
}

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

// S3
variable "s3_buckets_without_lifecycle_policy_trigger_enabled" {
  type    = bool
  default = false
}

variable "s3_buckets_without_lifecycle_policy_trigger_schedule" {
  type    = string
  default = "15m"
}

// SecretsManager
variable "secretsmanager_secrets_unused_trigger_enabled" {
  type    = bool
  default = false
}

variable "secretsmanager_secrets_unused_trigger_schedule" {
  type    = string
  default = "15m"
}

// VPC
variable "vpc_unattached_elastic_ip_addresses_trigger_enabled" {
  type    = bool
  default = false
}

variable "vpc_unattached_elastic_ip_addresses_trigger_schedule" {
  type    = string
  default = "15m"
}

variable "vpc_unused_nat_gateways_trigger_enabled" {
  type    = bool
  default = false
}

variable "vpc_unused_nat_gateways_trigger_schedule" {
  type    = string
  default = "15m"
}