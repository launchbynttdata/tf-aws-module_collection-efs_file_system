// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

# Complete Example - EFS Collection Module with All Features
# Demonstrates comprehensive usage including One Zone storage, custom KMS encryption,
# provisioned throughput, replication protection, and the resource naming module

# ========================================
# Data Sources
# ========================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ========================================
# Resource Naming Module
# ========================================

module "resource_names" {
  source = "git::https://github.com/launchbynttdata/tf-launch-module_library-resource_name.git?ref=2.2.0"

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  region                  = data.aws_region.current.name
  class_env               = var.environment
  cloud_resource_type     = "efs"
  separator               = "-"
  use_azure_region_abbr   = false
  instance_env            = var.instance_env
  instance_resource       = var.instance_resource
}

# ========================================
# VPC and Networking Infrastructure
# ========================================
# Minimal VPC setup to demonstrate EFS mount targets
# EFS is a private service and does not require internet connectivity

resource "aws_vpc" "complete" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${module.resource_names.standard}-vpc"
    }
  )
}

# Subnets with explicit AZ configuration
# Using explicit subnet configs allows for stable mount target keys
resource "aws_subnet" "multi_az" {
  count = length(local.subnet_configs_with_full_az)

  vpc_id            = aws_vpc.complete.id
  cidr_block        = local.subnet_configs_with_full_az[count.index].cidr_block
  availability_zone = local.subnet_configs_with_full_az[count.index].availability_zone

  tags = merge(
    local.common_tags,
    {
      Name = "${module.resource_names.standard}-subnet-${local.subnet_configs_with_full_az[count.index].availability_zone}"
      Tier = "private"
      AZ   = local.subnet_configs_with_full_az[count.index].availability_zone
    }
  )
}

# Single subnet for One Zone storage demonstration (if enabled)
resource "aws_subnet" "one_zone" {
  count = var.use_one_zone_storage ? 1 : 0

  vpc_id            = aws_vpc.complete.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 100)
  availability_zone = var.one_zone_availability_zone != null ? var.one_zone_availability_zone : "${data.aws_region.current.name}a"

  tags = merge(
    local.common_tags,
    {
      Name = "${module.resource_names.standard}-one-zone"
      Tier = "private"
      Type = "OneZone"
    }
  )
}

# ========================================
# Security Groups
# ========================================

# Security group for EFS mount targets
resource "aws_security_group" "efs_mount_target" {
  name_prefix = "${module.resource_names.standard}-efs-mt-"
  description = "Security group for EFS mount targets - allows NFS traffic"
  vpc_id      = aws_vpc.complete.id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.complete.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${module.resource_names.standard}-efs-mt-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ========================================
# KMS Key for EFS Encryption
# ========================================

resource "aws_kms_key" "efs" {
  description             = "KMS key for EFS encryption - ${module.resource_names.standard}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = var.enable_kms_key_rotation

  tags = merge(
    local.common_tags,
    {
      Name = "${module.resource_names.standard}-efs-key"
    }
  )
}

resource "aws_kms_alias" "efs" {
  name          = "alias/${module.resource_names.standard}-efs"
  target_key_id = aws_kms_key.efs.key_id
}

# KMS key policy
resource "aws_kms_key_policy" "efs" {
  key_id = aws_kms_key.efs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EFS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "elasticfilesystem.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "elasticfilesystem.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ========================================
# EFS Collection Module - Complete Configuration
# ========================================

module "efs" {
  source = "../../"

  # Use the resource naming module output
  name        = module.resource_names.standard
  environment = var.environment

  # ========================================
  # File System Configuration - All Options
  # ========================================

  # Override the default file system name if desired
  file_system_name = var.custom_file_system_name

  # One Zone storage (if enabled) - reduces cost but limits to single AZ
  availability_zone_name = var.use_one_zone_storage ? (var.one_zone_availability_zone != null ? var.one_zone_availability_zone : data.aws_availability_zones.available.names[0]) : null

  # Encryption with customer-managed KMS key
  encrypted  = true
  kms_key_id = aws_kms_key.efs.arn

  # Performance configuration
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  # Provisioned throughput (only used when throughput_mode = "provisioned")
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  # Comprehensive lifecycle policy with all transitions
  lifecycle_policy = {
    transition_to_ia                    = var.lifecycle_transition_to_ia
    transition_to_primary_storage_class = var.lifecycle_transition_to_primary
    transition_to_archive               = var.lifecycle_transition_to_archive
  }

  # Protection configuration (for replication scenarios)
  protection = var.enable_replication_protection ? {
    replication_overwrite = var.replication_overwrite_protection
  } : null

  # ========================================
  # Mount Target Configuration - Complete
  # ========================================

  create_mount_targets = true

  # Use mount target subnets from locals (handles One Zone vs Multi-AZ)
  # Keys are static (az-a, az-b, az-c or one-zone) and known at plan time
  mount_target_subnet_ids = local.mount_target_subnets

  mount_target_security_group_ids = [aws_security_group.efs_mount_target.id]

  # Custom timeouts for mount target operations
  mount_target_create_timeout = var.mount_target_create_timeout
  mount_target_delete_timeout = var.mount_target_delete_timeout

  # ========================================
  # Access Point Configuration - Multiple Applications
  # ========================================

  access_point_configurations = var.access_point_configurations

  # ========================================
  # Common Tags
  # ========================================

  tags = local.common_tags
}

# ========================================
# CloudWatch Alarms for Monitoring
# ========================================

resource "aws_cloudwatch_metric_alarm" "efs_burst_credit_balance" {
  count = var.throughput_mode == "bursting" ? 1 : 0

  alarm_name          = "${module.resource_names.standard}-efs-burst-credit-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = var.burst_credit_alarm_threshold
  alarm_description   = "EFS burst credit balance is low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = module.efs.file_system_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "efs_client_connections" {
  alarm_name          = "${module.resource_names.standard}-efs-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ClientConnections"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = var.client_connections_alarm_threshold
  alarm_description   = "High number of client connections to EFS"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FileSystemId = module.efs.file_system_id
  }

  tags = local.common_tags
}
