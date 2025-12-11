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
# EFS COLLECTION MODULE OUTPUTS
# ========================================
# Aggregates outputs from EFS file system, mount targets, and access points

# ========================================
# EFS File System Outputs
# ========================================

output "file_system" {
  description = "Complete output object from the EFS file system module."
  value       = module.efs_file_system
}

output "file_system_id" {
  description = "The ID of the EFS file system."
  value       = module.efs_file_system.file_system_id
}

output "file_system_arn" {
  description = "The ARN of the EFS file system."
  value       = module.efs_file_system.file_system_arn
}

output "file_system_dns_name" {
  description = "The DNS name for the EFS file system (format: file-system-id.efs.aws-region.amazonaws.com)."
  value       = module.efs_file_system.file_system_dns_name
}

output "file_system_name" {
  description = "The name (creation token) of the EFS file system."
  value       = module.efs_file_system.file_system_name
}

output "file_system_creation_token" {
  description = "The creation token of the EFS file system."
  value       = module.efs_file_system.file_system_creation_token
}

output "file_system_availability_zone_id" {
  description = "The identifier of the Availability Zone in which the file system's One Zone storage classes exist."
  value       = module.efs_file_system.file_system_availability_zone_id
}

output "file_system_availability_zone_name" {
  description = "The Availability Zone name in which the file system's One Zone storage classes exist."
  value       = module.efs_file_system.file_system_availability_zone_name
}

# ========================================
# EFS Mount Target Outputs
# ========================================

output "mount_target_ids" {
  description = "Map of mount target name to mount target ID."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_id }
}

output "mount_target_dns_names" {
  description = "Map of mount target name to mount target DNS name (format: file-system-id.efs.aws-region.amazonaws.com)."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_dns_name }
}

output "mount_target_az_dns_names" {
  description = "Map of mount target name to mount target AZ-specific DNS name (format: availability-zone.file-system-id.efs.aws-region.amazonaws.com)."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_az_dns_name }
}

output "mount_target_network_interface_ids" {
  description = "Map of mount target name to network interface ID created for the mount target."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_network_interface_id }
}

output "mount_target_availability_zone_names" {
  description = "Map of mount target name to availability zone name where the mount target resides."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_availability_zone_name }
}

output "mount_target_availability_zone_ids" {
  description = "Map of mount target name to availability zone ID where the mount target resides."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_availability_zone_id }
}

output "mount_target_file_system_arns" {
  description = "Map of mount target name to EFS file system ARN."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_file_system_arn }
}

output "mount_target_owner_ids" {
  description = "Map of mount target name to AWS account ID that owns the mount target resource."
  value       = { for k, v in module.efs_mount_target : k => v.mount_target_owner_id }
}

output "mount_targets" {
  description = "Complete output objects from all EFS mount target modules, keyed by mount target name."
  value       = module.efs_mount_target
}

# ========================================
# EFS Access Point Outputs
# ========================================

output "access_point_ids" {
  description = "Map of access point names to their IDs."
  value       = { for k, v in module.efs_access_point : k => v.access_point_id }
}

output "access_point_arns" {
  description = "Map of access point names to their ARNs."
  value       = { for k, v in module.efs_access_point : k => v.access_point_arn }
}

output "access_point_file_system_ids" {
  description = "Map of access point names to their file system IDs."
  value       = { for k, v in module.efs_access_point : k => v.file_system_id }
}

output "access_point_owner_ids" {
  description = "Map of access point names to AWS account IDs that own the access point resources."
  value       = { for k, v in module.efs_access_point : k => v.owner_id }
}

output "access_point_posix_users" {
  description = "Map of access point names to their POSIX user configurations."
  value       = { for k, v in module.efs_access_point : k => v.posix_user }
}

output "access_point_root_directories" {
  description = "Map of access point names to their root directory configurations."
  value       = { for k, v in module.efs_access_point : k => v.root_directory }
}

output "access_point_tags" {
  description = "Map of access point names to their tags."
  value       = { for k, v in module.efs_access_point : k => v.tags }
}

output "access_points" {
  description = "Complete output objects from all access point modules, keyed by access point name."
  value       = module.efs_access_point
}

# ========================================
# Aggregated Outputs
# ========================================

output "all_resource_arns" {
  description = "Combined list of all resource ARNs created by this EFS collection module."
  value = concat(
    [module.efs_file_system.file_system_arn],
    values({ for k, v in module.efs_access_point : k => v.access_point_arn })
  )
}

output "connection_info" {
  description = "Connection information for mounting the EFS file system."
  value = {
    file_system_id   = module.efs_file_system.file_system_id
    file_system_arn  = module.efs_file_system.file_system_arn
    dns_name         = module.efs_file_system.file_system_dns_name
    mount_target_dns = { for k, v in module.efs_mount_target : k => v.mount_target_dns_name }
    mount_target_azs = { for k, v in module.efs_mount_target : k => v.mount_target_az_dns_name }
    access_point_ids = { for k, v in module.efs_access_point : k => v.access_point_id }
  }
}

output "mount_command" {
  description = "Example mount command for mounting the EFS file system (adjust as needed for your use case)."
  value       = "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${module.efs_file_system.file_system_dns_name}:/ /mnt/efs"
}

output "mount_command_with_efs_utils" {
  description = "Example mount command using efs-utils helper (recommended - requires amazon-efs-utils package)."
  value       = "sudo mount -t efs ${module.efs_file_system.file_system_id}:/ /mnt/efs"
}
