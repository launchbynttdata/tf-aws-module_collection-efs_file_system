# tf-aws-module_collection-efs_file_system

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_efs_file_system"></a> [efs\_file\_system](#module\_efs\_file\_system) | github.com/launchbynttdata/tf-aws-module_primitive-efs_file_system | 2.0.0 |
| <a name="module_efs_mount_target"></a> [efs\_mount\_target](#module\_efs\_mount\_target) | github.com/launchbynttdata/tf-aws-module_primitive-efs_mount_target | 1.0.0 |
| <a name="module_efs_access_point"></a> [efs\_access\_point](#module\_efs\_access\_point) | github.com/launchbynttdata/tf-aws-module_primitive-efs_access_point | 0.2.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name prefix for all EFS resources created by this collection module. Used to generate names for file system, mount targets, and access points. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, staging, prod). Used for tagging and naming across all EFS sub-modules. | `string` | n/a | yes |
| <a name="input_file_system_name"></a> [file\_system\_name](#input\_file\_system\_name) | Name (creation token) for the EFS file system. If null, will be derived from var.name and var.environment. | `string` | `null` | no |
| <a name="input_availability_zone_name"></a> [availability\_zone\_name](#input\_availability\_zone\_name) | The AWS Availability Zone in which to create the file system. Used to create a file system that uses One Zone storage classes. If omitted, Multi-AZ storage will be used. | `string` | `null` | no |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | Whether to encrypt the EFS file system at rest. Highly recommended for production environments. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ARN of the KMS key to use for encryption. If null and encrypted=true, AWS managed key is used. | `string` | `null` | no |
| <a name="input_performance_mode"></a> [performance\_mode](#input\_performance\_mode) | Performance mode for the file system. Valid values: generalPurpose, maxIO. | `string` | `"generalPurpose"` | no |
| <a name="input_throughput_mode"></a> [throughput\_mode](#input\_throughput\_mode) | Throughput mode for the file system. Valid values: bursting, provisioned, elastic. | `string` | `"bursting"` | no |
| <a name="input_provisioned_throughput_in_mibps"></a> [provisioned\_throughput\_in\_mibps](#input\_provisioned\_throughput\_in\_mibps) | Provisioned throughput in MiB/s. Required when throughput\_mode is 'provisioned'. Valid values: 1-1024. | `number` | `null` | no |
| <a name="input_lifecycle_policy"></a> [lifecycle\_policy](#input\_lifecycle\_policy) | Lifecycle policy for the EFS file system. Defines when files transition to Infrequent Access and Archive storage classes. | <pre>object({<br/>    transition_to_ia                    = optional(string)<br/>    transition_to_primary_storage_class = optional(string)<br/>    transition_to_archive               = optional(string)<br/>  })</pre> | <pre>{<br/>  "transition_to_ia": "AFTER_30_DAYS"<br/>}</pre> | no |
| <a name="input_protection"></a> [protection](#input\_protection) | Protection configuration for the file system. Supports replication\_overwrite (ENABLED, DISABLED, REPLICATING). | <pre>object({<br/>    replication_overwrite = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_file_system_tags"></a> [file\_system\_tags](#input\_file\_system\_tags) | Additional tags for the EFS file system resource. Merged with common tags. | `map(string)` | `{}` | no |
| <a name="input_create_mount_targets"></a> [create\_mount\_targets](#input\_create\_mount\_targets) | Whether to create EFS mount targets. Set to false to skip mount target creation. | `bool` | `true` | no |
| <a name="input_mount_target_subnet_ids"></a> [mount\_target\_subnet\_ids](#input\_mount\_target\_subnet\_ids) | Map of mount target names to subnet IDs where EFS mount targets should be created. Keys are static names (e.g., 'az1', 'az2'), values are subnet IDs. Typically one per availability zone for high availability. | `map(string)` | `{}` | no |
| <a name="input_mount_target_security_group_ids"></a> [mount\_target\_security\_group\_ids](#input\_mount\_target\_security\_group\_ids) | List of security group IDs for the EFS mount targets. Must allow NFS traffic (port 2049) from clients. | `list(string)` | `[]` | no |
| <a name="input_mount_target_create_timeout"></a> [mount\_target\_create\_timeout](#input\_mount\_target\_create\_timeout) | Timeout for creating mount targets (e.g., '30m'). | `string` | `"30m"` | no |
| <a name="input_mount_target_delete_timeout"></a> [mount\_target\_delete\_timeout](#input\_mount\_target\_delete\_timeout) | Timeout for deleting mount targets (e.g., '10m'). | `string` | `"10m"` | no |
| <a name="input_access_point_configurations"></a> [access\_point\_configurations](#input\_access\_point\_configurations) | Map of access point configurations. Each key becomes an access point name. Access points provide application-specific entry points into the file system. | <pre>map(object({<br/>    posix_user = object({<br/>      uid            = number<br/>      gid            = number<br/>      secondary_gids = optional(list(number))<br/>    })<br/>    root_directory_path = string<br/>    root_directory_creation_info = optional(object({<br/>      owner_uid   = number<br/>      owner_gid   = number<br/>      permissions = string<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all EFS resources created by this collection module. These are merged with resource-specific tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_file_system"></a> [file\_system](#output\_file\_system) | Complete output object from the EFS file system module. |
| <a name="output_file_system_id"></a> [file\_system\_id](#output\_file\_system\_id) | The ID of the EFS file system. |
| <a name="output_file_system_arn"></a> [file\_system\_arn](#output\_file\_system\_arn) | The ARN of the EFS file system. |
| <a name="output_file_system_dns_name"></a> [file\_system\_dns\_name](#output\_file\_system\_dns\_name) | The DNS name for the EFS file system (format: file-system-id.efs.aws-region.amazonaws.com). |
| <a name="output_file_system_name"></a> [file\_system\_name](#output\_file\_system\_name) | The name (creation token) of the EFS file system. |
| <a name="output_file_system_creation_token"></a> [file\_system\_creation\_token](#output\_file\_system\_creation\_token) | The creation token of the EFS file system. |
| <a name="output_file_system_availability_zone_id"></a> [file\_system\_availability\_zone\_id](#output\_file\_system\_availability\_zone\_id) | The identifier of the Availability Zone in which the file system's One Zone storage classes exist. |
| <a name="output_file_system_availability_zone_name"></a> [file\_system\_availability\_zone\_name](#output\_file\_system\_availability\_zone\_name) | The Availability Zone name in which the file system's One Zone storage classes exist. |
| <a name="output_mount_target_ids"></a> [mount\_target\_ids](#output\_mount\_target\_ids) | Map of mount target name to mount target ID. |
| <a name="output_mount_target_dns_names"></a> [mount\_target\_dns\_names](#output\_mount\_target\_dns\_names) | Map of mount target name to mount target DNS name (format: file-system-id.efs.aws-region.amazonaws.com). |
| <a name="output_mount_target_az_dns_names"></a> [mount\_target\_az\_dns\_names](#output\_mount\_target\_az\_dns\_names) | Map of mount target name to mount target AZ-specific DNS name (format: availability-zone.file-system-id.efs.aws-region.amazonaws.com). |
| <a name="output_mount_target_network_interface_ids"></a> [mount\_target\_network\_interface\_ids](#output\_mount\_target\_network\_interface\_ids) | Map of mount target name to network interface ID created for the mount target. |
| <a name="output_mount_target_availability_zone_names"></a> [mount\_target\_availability\_zone\_names](#output\_mount\_target\_availability\_zone\_names) | Map of mount target name to availability zone name where the mount target resides. |
| <a name="output_mount_target_availability_zone_ids"></a> [mount\_target\_availability\_zone\_ids](#output\_mount\_target\_availability\_zone\_ids) | Map of mount target name to availability zone ID where the mount target resides. |
| <a name="output_mount_target_file_system_arns"></a> [mount\_target\_file\_system\_arns](#output\_mount\_target\_file\_system\_arns) | Map of mount target name to EFS file system ARN. |
| <a name="output_mount_target_owner_ids"></a> [mount\_target\_owner\_ids](#output\_mount\_target\_owner\_ids) | Map of mount target name to AWS account ID that owns the mount target resource. |
| <a name="output_mount_targets"></a> [mount\_targets](#output\_mount\_targets) | Complete output objects from all EFS mount target modules, keyed by mount target name. |
| <a name="output_access_point_ids"></a> [access\_point\_ids](#output\_access\_point\_ids) | Map of access point names to their IDs. |
| <a name="output_access_point_arns"></a> [access\_point\_arns](#output\_access\_point\_arns) | Map of access point names to their ARNs. |
| <a name="output_access_point_file_system_ids"></a> [access\_point\_file\_system\_ids](#output\_access\_point\_file\_system\_ids) | Map of access point names to their file system IDs. |
| <a name="output_access_point_owner_ids"></a> [access\_point\_owner\_ids](#output\_access\_point\_owner\_ids) | Map of access point names to AWS account IDs that own the access point resources. |
| <a name="output_access_point_posix_users"></a> [access\_point\_posix\_users](#output\_access\_point\_posix\_users) | Map of access point names to their POSIX user configurations. |
| <a name="output_access_point_root_directories"></a> [access\_point\_root\_directories](#output\_access\_point\_root\_directories) | Map of access point names to their root directory configurations. |
| <a name="output_access_point_tags"></a> [access\_point\_tags](#output\_access\_point\_tags) | Map of access point names to their tags. |
| <a name="output_access_points"></a> [access\_points](#output\_access\_points) | Complete output objects from all access point modules, keyed by access point name. |
| <a name="output_all_resource_arns"></a> [all\_resource\_arns](#output\_all\_resource\_arns) | Combined list of all resource ARNs created by this EFS collection module. |
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Connection information for mounting the EFS file system. |
| <a name="output_mount_command"></a> [mount\_command](#output\_mount\_command) | Example mount command for mounting the EFS file system (adjust as needed for your use case). |
| <a name="output_mount_command_with_efs_utils"></a> [mount\_command\_with\_efs\_utils](#output\_mount\_command\_with\_efs\_utils) | Example mount command using efs-utils helper (recommended - requires amazon-efs-utils package). |
<!-- END_TF_DOCS -->
