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

output "mount_target_ids" {
  description = "Map of subnet ID to mount target ID"
  value       = module.efs.mount_target_ids
}

output "access_point_ids" {
  description = "Map of access point names to their IDs"
  value       = module.efs.access_point_ids
}

output "mount_command" {
  description = "Command to mount the EFS file system"
  value       = module.efs.mount_command
}

output "connection_info" {
  description = "Connection information for the EFS file system"
  value       = module.efs.connection_info
}
