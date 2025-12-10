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
# Local Variables
# ========================================

locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Name        = module.resource_names.standard
    }
  )

  # Construct full AZ names from region and letters
  subnet_configs_with_full_az = [
    for config in var.subnet_configs : {
      cidr_block        = config.cidr_block
      availability_zone = "${var.aws_region}${config.az_letter}"
      az_letter         = config.az_letter
    }
  ]

  # Create a map of mount targets with static keys and subnet IDs as values
  # Keys are static (az-a, az-b, az-c) so they're known at plan time
  all_mount_targets = {
    for idx, config in local.subnet_configs_with_full_az :
    "az-${config.az_letter}" => aws_subnet.multi_az[idx].id
  }

  # Filter based on enabled_subnet_indices if provided
  # This allows for testing scenarios where we add/remove mount targets
  enabled_mount_targets = (var.enabled_subnet_indices != null && length(var.enabled_subnet_indices) > 0) ? {
    for idx in var.enabled_subnet_indices :
    "az-${local.subnet_configs_with_full_az[idx].az_letter}" => local.all_mount_targets["az-${local.subnet_configs_with_full_az[idx].az_letter}"]
  } : local.all_mount_targets

  # Final mount target subnet map for the EFS module
  # Use One Zone subnet if enabled, otherwise use multi-AZ subnets
  mount_target_subnets = var.use_one_zone_storage ? {
    "one-zone" = aws_subnet.one_zone[0].id
  } : local.enabled_mount_targets
}
