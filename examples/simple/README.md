# Simple Example

This example demonstrates the **minimum viable configuration** required to use the module. It provides a basic, working implementation with only essential parameters.

## Purpose

This simple example demonstrates **collection module** usage for EFS:

- Shows the minimum required configuration
- Creates supporting infrastructure (VPC, subnets, security groups)
- Calls the EFS collection module which orchestrates primitive modules
- Collection module internally creates AWS resources via primitive modules
- Can be quickly deployed and destroyed for testing

## Resources Created

### By This Example (Supporting Infrastructure)

- VPC
- 2 Subnets (across multiple AZs)
- Security Group (NFS port 2049)
- Availability Zone data source

### By Collection Module (via Primitive Modules)

- **EFS File System** (via efs_file_system primitive module)
- **Mount Targets** (via efs_mount_target primitive module - one per subnet)
- **Access Points** (via efs_access_point primitive module - 2 access points: app1 and app2)

**Note:** The collection module (../../) calls primitive modules, which create the actual AWS resources.

## Usage

```hcl
# Supporting infrastructure (created in this example)
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Collection module call (orchestrates primitive modules)
module "efs" {
  source = "../.."

  name        = "efs-test"
  environment = "dev"

  # File system configuration
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Mount target configuration
  create_mount_targets            = true
  mount_target_subnet_ids         = { for idx, subnet in aws_subnet.example : "subnet-${idx + 1}" => subnet.id }
  mount_target_security_group_ids = [aws_security_group.efs_mount_target.id]

  # Access points
  access_point_configurations = var.access_point_configurations
}
```

## Prerequisites

- AWS credentials configured
- Terraform >= 1.5 installed
- Appropriate AWS permissions to create resources

## Inputs

See the terraform-docs generated table below for all available inputs.

## Outputs

See the terraform-docs generated table below for all available outputs.

## How to Run

### Initialize Terraform

```bash
terraform init
```

### Plan the Deployment

```bash
terraform plan -var-file=test.tfvars
```

### Apply the Configuration

```bash
terraform apply -var-file=test.tfvars
```

### View Outputs

```bash
terraform output
```

## Cleanup

To destroy all resources created by this example:

```bash
terraform destroy -var-file=test.tfvars
```

## Notes

- This example creates supporting infrastructure (VPC, subnets, etc.) for demonstration purposes
- In production, you would typically reference existing infrastructure
- Modify `test.tfvars` to customize variable values
- Review and adjust resource configurations as needed for your use case

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_efs"></a> [efs](#module\_efs) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.efs_mount_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_name"></a> [resource\_name](#input\_resource\_name) | Name for example resources | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR for example VPC | `string` | n/a | yes |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | Whether to encrypt the EFS file system | `bool` | `true` | no |
| <a name="input_performance_mode"></a> [performance\_mode](#input\_performance\_mode) | Performance mode for the file system | `string` | `"generalPurpose"` | no |
| <a name="input_throughput_mode"></a> [throughput\_mode](#input\_throughput\_mode) | Throughput mode for the file system | `string` | `"bursting"` | no |
| <a name="input_lifecycle_policy"></a> [lifecycle\_policy](#input\_lifecycle\_policy) | Lifecycle policy configuration | <pre>object({<br/>    transition_to_ia                    = optional(string)<br/>    transition_to_primary_storage_class = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_access_point_configurations"></a> [access\_point\_configurations](#input\_access\_point\_configurations) | Map of access point configurations | <pre>map(object({<br/>    posix_user = object({<br/>      uid            = number<br/>      gid            = number<br/>      secondary_gids = optional(list(number))<br/>    })<br/>    root_directory_path = string<br/>    root_directory_creation_info = optional(object({<br/>      owner_uid   = number<br/>      owner_gid   = number<br/>      permissions = string<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_file_system_id"></a> [file\_system\_id](#output\_file\_system\_id) | The ID of the EFS file system |
| <a name="output_file_system_arn"></a> [file\_system\_arn](#output\_file\_system\_arn) | The ARN of the EFS file system |
| <a name="output_file_system_dns_name"></a> [file\_system\_dns\_name](#output\_file\_system\_dns\_name) | The DNS name for the EFS file system |
| <a name="output_file_system_name"></a> [file\_system\_name](#output\_file\_system\_name) | The name of the EFS file system |
| <a name="output_file_system_creation_token"></a> [file\_system\_creation\_token](#output\_file\_system\_creation\_token) | The creation token of the EFS file system |
| <a name="output_file_system_availability_zone_id"></a> [file\_system\_availability\_zone\_id](#output\_file\_system\_availability\_zone\_id) | The AZ ID for One Zone storage (empty for Multi-AZ) |
| <a name="output_file_system_availability_zone_name"></a> [file\_system\_availability\_zone\_name](#output\_file\_system\_availability\_zone\_name) | The AZ name for One Zone storage (empty for Multi-AZ) |
| <a name="output_mount_target_ids"></a> [mount\_target\_ids](#output\_mount\_target\_ids) | Map of subnet ID to mount target ID |
| <a name="output_mount_target_dns_names"></a> [mount\_target\_dns\_names](#output\_mount\_target\_dns\_names) | Map of mount target DNS names |
| <a name="output_mount_target_az_dns_names"></a> [mount\_target\_az\_dns\_names](#output\_mount\_target\_az\_dns\_names) | Map of mount target AZ-specific DNS names |
| <a name="output_mount_target_network_interface_ids"></a> [mount\_target\_network\_interface\_ids](#output\_mount\_target\_network\_interface\_ids) | Map of mount target network interface IDs |
| <a name="output_mount_target_availability_zone_names"></a> [mount\_target\_availability\_zone\_names](#output\_mount\_target\_availability\_zone\_names) | Map of mount target availability zone names |
| <a name="output_mount_target_availability_zone_ids"></a> [mount\_target\_availability\_zone\_ids](#output\_mount\_target\_availability\_zone\_ids) | Map of mount target availability zone IDs |
| <a name="output_mount_target_file_system_arns"></a> [mount\_target\_file\_system\_arns](#output\_mount\_target\_file\_system\_arns) | Map of mount target file system ARNs |
| <a name="output_mount_target_owner_ids"></a> [mount\_target\_owner\_ids](#output\_mount\_target\_owner\_ids) | Map of mount target owner IDs |
| <a name="output_access_point_ids"></a> [access\_point\_ids](#output\_access\_point\_ids) | Map of access point names to their IDs |
| <a name="output_access_point_arns"></a> [access\_point\_arns](#output\_access\_point\_arns) | Map of access point names to their ARNs |
| <a name="output_access_point_file_system_ids"></a> [access\_point\_file\_system\_ids](#output\_access\_point\_file\_system\_ids) | Map of access point names to their file system IDs |
| <a name="output_access_point_owner_ids"></a> [access\_point\_owner\_ids](#output\_access\_point\_owner\_ids) | Map of access point names to their owner IDs |
| <a name="output_access_point_posix_users"></a> [access\_point\_posix\_users](#output\_access\_point\_posix\_users) | Map of access point names to their POSIX user configurations |
| <a name="output_access_point_root_directories"></a> [access\_point\_root\_directories](#output\_access\_point\_root\_directories) | Map of access point names to their root directory configurations |
| <a name="output_access_point_tags"></a> [access\_point\_tags](#output\_access\_point\_tags) | Map of access point names to their tags |
| <a name="output_mount_command"></a> [mount\_command](#output\_mount\_command) | Command to mount the EFS file system |
| <a name="output_connection_info"></a> [connection\_info](#output\_connection\_info) | Connection information for the EFS file system |
| <a name="output_mount_command_with_efs_utils"></a> [mount\_command\_with\_efs\_utils](#output\_mount\_command\_with\_efs\_utils) | Command to mount the EFS file system using efs-utils |
| <a name="output_all_resource_arns"></a> [all\_resource\_arns](#output\_all\_resource\_arns) | Combined list of all resource ARNs created by the EFS collection |
<!-- END_TF_DOCS -->
