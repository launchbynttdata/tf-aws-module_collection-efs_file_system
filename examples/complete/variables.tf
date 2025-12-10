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

# ========================================
# Resource Naming Module Variables
# ========================================

variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "logical_product_family" {
  description = "Logical product family for the resource naming module"
  type        = string
}

variable "logical_product_service" {
  description = "Logical product service for the resource naming module"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "instance_env" {
  description = "Instance environment number"
  type        = number
  default     = 0
}

variable "instance_resource" {
  description = "Instance resource number"
  type        = number
  default     = 0
}

# ========================================
# VPC and Networking Variables
# ========================================

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_configs" {
  description = "List of subnet configurations with CIDR blocks and AZ letter suffixes (e.g., 'a', 'b', 'c'). The full AZ name will be constructed as region + az_letter."
  type = list(object({
    cidr_block = string
    az_letter  = string
  }))

  validation {
    condition     = length(var.subnet_configs) > 0
    error_message = "At least one subnet configuration must be provided."
  }

  validation {
    condition = alltrue([
      for config in var.subnet_configs : can(cidrhost(config.cidr_block, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR blocks."
  }

  validation {
    condition = alltrue([
      for config in var.subnet_configs : can(regex("^[a-z]$", config.az_letter))
    ])
    error_message = "All AZ letters must be single lowercase letters (a-z)."
  }
}

variable "enabled_subnet_indices" {
  description = <<-EOT
    List of subnet indices (0-based) to create mount targets in.
    If null or empty, mount targets will be created in all subnets.

    Example: [0, 2] creates mount targets only in the 1st and 3rd subnets.
    This allows testing subnet removal/addition without rebuilding existing mount targets.
  EOT
  type        = list(number)
  default     = null

  validation {
    condition = var.enabled_subnet_indices == null || alltrue([
      for idx in var.enabled_subnet_indices : idx >= 0
    ])
    error_message = "All subnet indices must be non-negative integers."
  }
}

variable "use_one_zone_storage" {
  description = "Whether to use One Zone storage class instead of Multi-AZ (reduces cost)"
  type        = bool
  default     = false
}

variable "one_zone_availability_zone" {
  description = "Specific availability zone for One Zone storage. If null, uses first available AZ"
  type        = string
  default     = null
}

# ========================================
# KMS Encryption Variables
# ========================================

variable "kms_deletion_window_days" {
  description = "Number of days before KMS key deletion (7-30 days)"
  type        = number
  default     = 10
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

# ========================================
# EFS File System Variables - All Options
# ========================================

variable "custom_file_system_name" {
  description = "Custom name for the EFS file system. If null, uses resource_names module output"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "Performance mode: generalPurpose or maxIO"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "Throughput mode: bursting, provisioned, or elastic"
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be one of: bursting, provisioned, elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s (only used when throughput_mode = provisioned)"
  type        = number
  default     = null

  validation {
    condition     = var.provisioned_throughput_in_mibps == null || (var.provisioned_throughput_in_mibps >= 1 && var.provisioned_throughput_in_mibps <= 1024)
    error_message = "Provisioned throughput must be between 1 and 1024 MiB/s."
  }
}

variable "lifecycle_transition_to_ia" {
  description = "When to transition files to Infrequent Access storage"
  type        = string
  default     = "AFTER_7_DAYS"

  validation {
    condition = contains([
      "AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS",
      "AFTER_60_DAYS", "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"
    ], var.lifecycle_transition_to_ia)
    error_message = "Must be a valid transition period."
  }
}

variable "lifecycle_transition_to_primary" {
  description = "When to transition files back to primary storage"
  type        = string
  default     = "AFTER_1_ACCESS"

  validation {
    condition     = var.lifecycle_transition_to_primary == null || var.lifecycle_transition_to_primary == "AFTER_1_ACCESS"
    error_message = "Must be AFTER_1_ACCESS or null."
  }
}

variable "lifecycle_transition_to_archive" {
  description = "When to transition files to Archive storage"
  type        = string
  default     = "AFTER_90_DAYS"

  validation {
    condition = contains([
      "AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS",
      "AFTER_60_DAYS", "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"
    ], var.lifecycle_transition_to_archive)
    error_message = "Must be a valid transition period."
  }
}

variable "enable_replication_protection" {
  description = "Enable replication protection configuration"
  type        = bool
  default     = false
}

variable "replication_overwrite_protection" {
  description = "Replication overwrite protection setting: ENABLED, DISABLED, or REPLICATING"
  type        = string
  default     = "ENABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED", "REPLICATING"], var.replication_overwrite_protection)
    error_message = "Must be ENABLED, DISABLED, or REPLICATING."
  }
}

# ========================================
# Mount Target Variables - All Options
# ========================================

variable "mount_target_create_timeout" {
  description = "Timeout for creating mount targets"
  type        = string
  default     = "30m"
}

variable "mount_target_delete_timeout" {
  description = "Timeout for deleting mount targets"
  type        = string
  default     = "15m"
}

# ========================================
# Access Point Configuration
# ========================================

variable "access_point_configurations" {
  description = "Map of access point configurations for different applications"
  type = map(object({
    posix_user = object({
      uid            = number
      gid            = number
      secondary_gids = optional(list(number))
    })
    root_directory_path = string
    root_directory_creation_info = optional(object({
      owner_uid   = number
      owner_gid   = number
      permissions = string
    }))
    tags = optional(map(string), {})
  }))
}

# ========================================
# Monitoring and Alarms
# ========================================

variable "burst_credit_alarm_threshold" {
  description = "Threshold for burst credit balance alarm (in bytes)"
  type        = number
  default     = 1000000000000 # 1 TiB
}

variable "client_connections_alarm_threshold" {
  description = "Threshold for client connections alarm"
  type        = number
  default     = 1000
}

# ========================================
# Common Tags
# ========================================

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
