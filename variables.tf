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
# EFS COLLECTION MODULE VARIABLES
# ========================================
# This collection module orchestrates EFS file system, mount targets, and access points.

# ========================================
# Required Variables - High Level
# ========================================

variable "name" {
  description = "Name prefix for all EFS resources created by this collection module. Used to generate names for file system, mount targets, and access points."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Name must be between 1 and 64 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Used for tagging and naming across all EFS sub-modules."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

# ========================================
# EFS File System Configuration
# ========================================

variable "file_system_name" {
  description = "Name (creation token) for the EFS file system. If null, will be derived from var.name and var.environment."
  type        = string
  default     = null
}

variable "availability_zone_name" {
  description = "The AWS Availability Zone in which to create the file system. Used to create a file system that uses One Zone storage classes. If omitted, Multi-AZ storage will be used."
  type        = string
  default     = null
}

variable "encrypted" {
  description = "Whether to encrypt the EFS file system at rest. Highly recommended for production environments."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encryption. If null and encrypted=true, AWS managed key is used."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws:kms:", var.kms_key_id))
    error_message = "KMS key ID must be a valid ARN starting with 'arn:aws:kms:'."
  }
}

variable "performance_mode" {
  description = "Performance mode for the file system. Valid values: generalPurpose, maxIO."
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system. Valid values: bursting, provisioned, elastic."
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be one of: bursting, provisioned, elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s. Required when throughput_mode is 'provisioned'. Valid values: 1-1024."
  type        = number
  default     = null

  validation {
    condition     = var.provisioned_throughput_in_mibps == null || (var.provisioned_throughput_in_mibps >= 1 && var.provisioned_throughput_in_mibps <= 1024)
    error_message = "Provisioned throughput must be between 1 and 1024 MiB/s."
  }
}

variable "lifecycle_policy" {
  description = "Lifecycle policy for the EFS file system. Defines when files transition to Infrequent Access and Archive storage classes."
  type = object({
    transition_to_ia                    = optional(string)
    transition_to_primary_storage_class = optional(string)
    transition_to_archive               = optional(string)
  })
  default = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  validation {
    condition = (
      var.lifecycle_policy.transition_to_ia == null ||
      contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"], var.lifecycle_policy.transition_to_ia)
    )
    error_message = "transition_to_ia must be one of: AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS."
  }

  validation {
    condition = (
      var.lifecycle_policy.transition_to_primary_storage_class == null ||
      contains(["AFTER_1_ACCESS"], var.lifecycle_policy.transition_to_primary_storage_class)
    )
    error_message = "transition_to_primary_storage_class must be AFTER_1_ACCESS."
  }

  validation {
    condition = (
      var.lifecycle_policy.transition_to_archive == null ||
      contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"], var.lifecycle_policy.transition_to_archive)
    )
    error_message = "transition_to_archive must be one of: AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS."
  }
}

variable "protection" {
  description = "Protection configuration for the file system. Supports replication_overwrite (ENABLED, DISABLED, REPLICATING)."
  type = object({
    replication_overwrite = optional(string)
  })
  default = null

  validation {
    condition = (
      var.protection == null ||
      var.protection.replication_overwrite == null ||
      contains(["ENABLED", "DISABLED", "REPLICATING"], var.protection.replication_overwrite)
    )
    error_message = "protection.replication_overwrite must be one of: ENABLED, DISABLED, REPLICATING."
  }
}

variable "file_system_tags" {
  description = "Additional tags for the EFS file system resource. Merged with common tags."
  type        = map(string)
  default     = {}
}

# ========================================
# EFS Mount Target Configuration
# ========================================

variable "create_mount_targets" {
  description = "Whether to create EFS mount targets. Set to false to skip mount target creation."
  type        = bool
  default     = true
}

variable "mount_target_subnet_ids" {
  description = "Map of mount target names to subnet IDs where EFS mount targets should be created. Keys are static names (e.g., 'az1', 'az2'), values are subnet IDs. Typically one per availability zone for high availability."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for id in values(var.mount_target_subnet_ids) : can(regex("^subnet-", id))])
    error_message = "All subnet IDs must start with 'subnet-'."
  }
}

variable "mount_target_security_group_ids" {
  description = "List of security group IDs for the EFS mount targets. Must allow NFS traffic (port 2049) from clients."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.mount_target_security_group_ids : can(regex("^sg-", id))])
    error_message = "All security group IDs must start with 'sg-'."
  }
}

variable "mount_target_create_timeout" {
  description = "Timeout for creating mount targets (e.g., '30m')."
  type        = string
  default     = "30m"
}

variable "mount_target_delete_timeout" {
  description = "Timeout for deleting mount targets (e.g., '10m')."
  type        = string
  default     = "10m"
}

# ========================================
# EFS Access Point Configuration
# ========================================

variable "access_point_configurations" {
  description = "Map of access point configurations. Each key becomes an access point name. Access points provide application-specific entry points into the file system."
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
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.access_point_configurations :
      v.posix_user.uid >= 0 && v.posix_user.uid <= 4294967295 &&
      v.posix_user.gid >= 0 && v.posix_user.gid <= 4294967295
    ])
    error_message = "POSIX user UID and GID must be between 0 and 4294967295."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_point_configurations :
      can(regex("^/.*", v.root_directory_path))
    ])
    error_message = "Root directory path must start with '/'."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_point_configurations :
      v.root_directory_creation_info == null ||
      can(regex("^[0-7]{3,4}$", v.root_directory_creation_info.permissions))
    ])
    error_message = "Directory permissions must be in octal format (e.g., '755', '0755')."
  }
}

# ========================================
# Shared Configuration Variables
# ========================================

variable "tags" {
  description = "Map of tags to apply to all EFS resources created by this collection module. These are merged with resource-specific tags."
  type        = map(string)
  default     = {}
}
