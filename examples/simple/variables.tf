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

# Example Variables for EFS Collection Module

variable "resource_name" {
  description = "Name for example resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Supporting Infrastructure Variables
variable "vpc_cidr_block" {
  description = "CIDR for example VPC"
  type        = string
}



# EFS File System Variables
variable "encrypted" {
  description = "Whether to encrypt the EFS file system"
  type        = bool
  default     = true
}

variable "performance_mode" {
  description = "Performance mode for the file system"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "Throughput mode for the file system"
  type        = string
  default     = "bursting"
}

variable "lifecycle_policy" {
  description = "Lifecycle policy configuration"
  type = object({
    transition_to_ia                    = optional(string)
    transition_to_primary_storage_class = optional(string)
  })
  default = null
}

# Access Point Configurations
variable "access_point_configurations" {
  description = "Map of access point configurations"
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

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
