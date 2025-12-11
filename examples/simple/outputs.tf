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

# Outputs for the simple example

output "file_system_id" {
  description = "The ID of the EFS file system"
  value       = module.efs.file_system_id
}

output "file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = module.efs.file_system_arn
}

output "file_system_dns_name" {
  description = "The DNS name for the EFS file system"
  value       = module.efs.file_system_dns_name
}

output "file_system_name" {
  description = "The name of the EFS file system"
  value       = module.efs.file_system_name
}

output "file_system_creation_token" {
  description = "The creation token of the EFS file system"
  value       = module.efs.file_system_creation_token
}

output "file_system_availability_zone_id" {
  description = "The AZ ID for One Zone storage (empty for Multi-AZ)"
  value       = module.efs.file_system_availability_zone_id
}

output "file_system_availability_zone_name" {
  description = "The AZ name for One Zone storage (empty for Multi-AZ)"
  value       = module.efs.file_system_availability_zone_name
}

output "mount_target_ids" {
  description = "Map of subnet ID to mount target ID"
  value       = module.efs.mount_target_ids
}

output "mount_target_dns_names" {
  description = "Map of mount target DNS names"
  value       = module.efs.mount_target_dns_names
}

output "mount_target_az_dns_names" {
  description = "Map of mount target AZ-specific DNS names"
  value       = module.efs.mount_target_az_dns_names
}

output "mount_target_network_interface_ids" {
  description = "Map of mount target network interface IDs"
  value       = module.efs.mount_target_network_interface_ids
}

output "mount_target_availability_zone_names" {
  description = "Map of mount target availability zone names"
  value       = module.efs.mount_target_availability_zone_names
}

output "mount_target_availability_zone_ids" {
  description = "Map of mount target availability zone IDs"
  value       = module.efs.mount_target_availability_zone_ids
}

output "mount_target_file_system_arns" {
  description = "Map of mount target file system ARNs"
  value       = module.efs.mount_target_file_system_arns
}

output "mount_target_owner_ids" {
  description = "Map of mount target owner IDs"
  value       = module.efs.mount_target_owner_ids
}

output "access_point_ids" {
  description = "Map of access point names to their IDs"
  value       = module.efs.access_point_ids
}

output "access_point_arns" {
  description = "Map of access point names to their ARNs"
  value       = module.efs.access_point_arns
}

output "access_point_file_system_ids" {
  description = "Map of access point names to their file system IDs"
  value       = module.efs.access_point_file_system_ids
}

output "access_point_owner_ids" {
  description = "Map of access point names to their owner IDs"
  value       = module.efs.access_point_owner_ids
}

output "access_point_posix_users" {
  description = "Map of access point names to their POSIX user configurations"
  value       = module.efs.access_point_posix_users
}

output "access_point_root_directories" {
  description = "Map of access point names to their root directory configurations"
  value       = module.efs.access_point_root_directories
}

output "access_point_tags" {
  description = "Map of access point names to their tags"
  value       = module.efs.access_point_tags
}

output "mount_command" {
  description = "Command to mount the EFS file system"
  value       = module.efs.mount_command
}

output "connection_info" {
  description = "Connection information for the EFS file system"
  value       = module.efs.connection_info
}

output "mount_command_with_efs_utils" {
  description = "Command to mount the EFS file system using efs-utils"
  value       = module.efs.mount_command_with_efs_utils
}

output "all_resource_arns" {
  description = "Combined list of all resource ARNs created by the EFS collection"
  value       = module.efs.all_resource_arns
}
