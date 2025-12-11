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
# Resource Naming Outputs
# ========================================

output "resource_name" {
  description = "Standardized resource name from the naming module"
  value       = module.resource_names.standard
}

# ========================================
# VPC and Networking Outputs
# ========================================

output "vpc_id" {
  description = "ID of the VPC created for the example"
  value       = aws_vpc.complete.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.complete.cidr_block
}

output "subnet_ids" {
  description = "IDs of all subnets created"
  value       = var.use_one_zone_storage ? aws_subnet.one_zone[*].id : aws_subnet.multi_az[*].id
}

output "security_group_id" {
  description = "ID of the EFS mount target security group"
  value       = aws_security_group.efs_mount_target.id
}

# ========================================
# KMS Outputs
# ========================================

output "kms_key_id" {
  description = "ID of the KMS key used for EFS encryption"
  value       = aws_kms_key.efs.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EFS encryption"
  value       = aws_kms_key.efs.arn
}

output "kms_alias_name" {
  description = "Name of the KMS key alias"
  value       = aws_kms_alias.efs.name
}

# ========================================
# EFS File System Outputs
# ========================================

output "file_system_id" {
  description = "ID of the EFS file system"
  value       = module.efs.file_system_id
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = module.efs.file_system_arn
}

output "file_system_dns_name" {
  description = "DNS name of the EFS file system"
  value       = module.efs.file_system_dns_name
}

output "file_system_creation_token" {
  description = "Creation token of the EFS file system"
  value       = module.efs.file_system_creation_token
}

output "file_system_availability_zone_id" {
  description = "Availability zone ID for One Zone storage (null for Multi-AZ)"
  value       = module.efs.file_system_availability_zone_id
}

output "file_system_availability_zone_name" {
  description = "Availability zone name for One Zone storage (null for Multi-AZ)"
  value       = module.efs.file_system_availability_zone_name
}

output "file_system_name" {
  description = "Name of the file system"
  value       = module.efs.file_system_name
}

# ========================================
# Mount Target Outputs
# ========================================

output "mount_target_ids" {
  description = "IDs of all mount targets"
  value       = module.efs.mount_target_ids
}

output "mount_target_dns_names" {
  description = "DNS names of all mount targets"
  value       = module.efs.mount_target_dns_names
}

output "mount_target_network_interface_ids" {
  description = "Network interface IDs of all mount targets"
  value       = module.efs.mount_target_network_interface_ids
}

output "mount_target_availability_zone_names" {
  description = "Availability zones of all mount targets"
  value       = module.efs.mount_target_availability_zone_names
}

output "mount_target_availability_zone_ids" {
  description = "Availability zone IDs of all mount targets"
  value       = module.efs.mount_target_availability_zone_ids
}

output "mount_target_file_system_arns" {
  description = "ARNs of the file system for each mount target"
  value       = module.efs.mount_target_file_system_arns
}

output "mount_target_owner_ids" {
  description = "AWS account IDs of the mount target owners"
  value       = module.efs.mount_target_owner_ids
}

output "mount_target_az_dns_names" {
  description = "AZ-specific DNS names for mount targets"
  value       = module.efs.mount_target_az_dns_names
}

# ========================================
# Access Point Outputs
# ========================================

output "access_point_ids" {
  description = "Map of access point names to IDs"
  value       = module.efs.access_point_ids
}

output "access_point_arns" {
  description = "Map of access point names to ARNs"
  value       = module.efs.access_point_arns
}

output "access_point_file_system_ids" {
  description = "Map of access point names to file system IDs"
  value       = module.efs.access_point_file_system_ids
}

output "access_point_owner_ids" {
  description = "Map of access point names to owner IDs"
  value       = module.efs.access_point_owner_ids
}

output "access_point_posix_users" {
  description = "Map of access point names to POSIX user configurations"
  value       = module.efs.access_point_posix_users
}

output "access_point_root_directories" {
  description = "Map of access point names to root directory configurations"
  value       = module.efs.access_point_root_directories
}

output "access_point_tags" {
  description = "Map of access point names to their tags"
  value       = module.efs.access_point_tags
}

# ========================================
# Aggregated Outputs
# ========================================

output "all_resource_arns" {
  description = "Combined list of all resource ARNs created by the EFS collection"
  value       = module.efs.all_resource_arns
}

output "connection_info" {
  description = "Connection information for mounting the EFS file system"
  value       = module.efs.connection_info
}

output "mount_command" {
  description = "Example mount command for mounting the EFS file system"
  value       = module.efs.mount_command
}

output "mount_command_with_efs_utils" {
  description = "Example mount command using efs-utils helper"
  value       = module.efs.mount_command_with_efs_utils
}

# ========================================
# CloudWatch Alarm Outputs
# ========================================

output "burst_credit_alarm_arn" {
  description = "ARN of the burst credit balance alarm (if created)"
  value       = var.throughput_mode == "bursting" ? aws_cloudwatch_metric_alarm.efs_burst_credit_balance[0].arn : null
}

output "client_connections_alarm_arn" {
  description = "ARN of the client connections alarm"
  value       = aws_cloudwatch_metric_alarm.efs_client_connections.arn
}

# ========================================
# Deployment Information
# ========================================

output "deployment_info" {
  description = "Summary of the deployed EFS configuration"
  value = {
    storage_type            = var.use_one_zone_storage ? "OneZone" : "MultiAZ"
    performance_mode        = var.performance_mode
    throughput_mode         = var.throughput_mode
    encryption              = "CustomKMS"
    number_of_mount_targets = length(var.use_one_zone_storage ? aws_subnet.one_zone[*].id : aws_subnet.multi_az[*].id)
    number_of_access_points = length(var.access_point_configurations)
    lifecycle_enabled       = true
    replication_protection  = var.enable_replication_protection
  }
}
