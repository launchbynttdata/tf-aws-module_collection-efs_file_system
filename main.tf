# EFS Collection Module
# This file orchestrates the creation of a complete EFS file system with mount targets and access points.
#
# Architecture:
# Collection Module → efs_file_system → efs_mount_target → efs_access_point
#
# This module ONLY calls other Terraform modules (primitive modules).
# It does not define AWS resources directly.

# ========================================
# EFS File System
# ========================================
# The primary resource - creates the EFS file system

module "efs_file_system" {
  source = "github.com/launchbynttdata/tf-aws-module_primitive-efs_file_system?ref=2.0.0"

  # File system configuration
  name                            = var.file_system_name != null ? var.file_system_name : local.file_system_name
  creation_token                  = var.file_system_name != null ? var.file_system_name : local.file_system_name
  availability_zone_name          = var.availability_zone_name
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps

  # Lifecycle and protection policies
  lifecycle_policy = var.lifecycle_policy
  protection       = var.protection

  # Tags
  tags = merge(
    local.common_tags,
    var.file_system_tags,
    {
      Component = "file-system"
    }
  )
}

# ========================================
# EFS Mount Targets
# ========================================
# Creates mount targets in specified subnets for VPC access to the file system
# Each mount target is created in a separate subnet (typically one per AZ)

module "efs_mount_target" {
  source = "github.com/launchbynttdata/tf-aws-module_primitive-efs_mount_target?ref=1.0.0"

  # Create one mount target per subnet using for_each
  # Only create mount targets if enabled and subnets are provided
  for_each = var.create_mount_targets ? var.mount_target_subnet_ids : {}

  # Reference the file system created above
  efs_filesystem_id = module.efs_file_system.file_system_id

  # Network configuration - single subnet per mount target
  subnet_id          = each.value
  security_group_ids = var.mount_target_security_group_ids
  ip_address         = null # Let AWS auto-assign IP addresses

  # Timeouts
  create_timeout = var.mount_target_create_timeout
  delete_timeout = var.mount_target_delete_timeout
}

# ========================================
# EFS Access Points
# ========================================
# Creates access points for application-specific file system access

module "efs_access_point" {
  source = "github.com/launchbynttdata/tf-aws-module_primitive-efs_access_point?ref=0.2.0"

  # Create one access point for each configuration provided
  for_each = var.access_point_configurations

  # Required parameters
  name               = "${var.name}-${each.key}"
  efs_file_system_id = module.efs_file_system.file_system_id

  # Access point configuration
  posix_user = each.value.posix_user
  root_directory = {
    path          = each.value.root_directory_path
    creation_info = each.value.root_directory_creation_info
  }

  # Tags - merge common tags with access point specific tags
  tags = merge(
    local.common_tags,
    try(each.value.tags, {}),
    {
      Component      = "access-point"
      AccessPointKey = each.key
    }
  )
}
