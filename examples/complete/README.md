# Complete Example - EFS Collection Module

This example demonstrates **comprehensive usage** of the EFS collection module, utilizing all available variables and configuration options. It includes:

- **Resource Naming Module**: Uses the `tf-launch-module_library-resource_name` module for standardized naming
- **Custom KMS Encryption**: Customer-managed KMS key with automatic rotation
- **Advanced Lifecycle Policies**: Tiered storage with IA and Archive transitions
- **Multiple Access Points**: Four different application access points with distinct permissions
- **Monitoring & Alarms**: CloudWatch alarms for burst credits and client connections
- **One Zone Storage Option**: Configurable for cost optimization
- **Provisioned Throughput**: Support for provisioned throughput mode
- **Replication Protection**: Configuration for multi-region replication scenarios

## Architecture

```text
VPC (10.1.0.0/16)
├── Private Subnets (Multi-AZ)
│   ├── Subnet 1 (10.1.0.0/24) - AZ-a
│   ├── Subnet 2 (10.1.1.0/24) - AZ-b
│   └── Subnet 3 (10.1.2.0/24) - AZ-c
│
├── Security Group (NFS - Port 2049)
│   └── Ingress: VPC CIDR
│
└── EFS File System
    ├── Custom KMS Encryption
    ├── Lifecycle Policies (IA + Archive)
    ├── Mount Targets (One per subnet)
    └── Access Points
        ├── /web (UID 1000)
        ├── /api (UID 2000)
        ├── /batch (UID 3000)
        └── /shared (UID 4000)
```

## Features Demonstrated

### 1. Resource Naming Module Integration

- Standardized naming across all resources
- Logical product family and service identification
- Environment-based naming conventions
- Regional context in names

### 2. File System Configuration

- **Performance Mode**: `generalPurpose` or `maxIO`
- **Throughput Mode**: `bursting`, `provisioned`, or `elastic`
- **Provisioned Throughput**: Custom MiB/s configuration
- **Availability Zone**: One Zone or Multi-AZ storage

### 3. Encryption

- Customer-managed KMS key
- Automatic key rotation
- Service-specific key policy
- KMS key alias for easy reference

### 4. Lifecycle Management

- **transition_to_ia**: Move to Infrequent Access after 7 days
- **transition_to_primary**: Move back to primary storage after access
- **transition_to_archive**: Move to Archive storage after 90 days

### 5. Protection Configuration

- Replication overwrite protection
- Support for ENABLED, DISABLED, and REPLICATING states

### 6. Mount Targets

- Multi-AZ deployment for high availability
- Custom IP addressing (optional)
- Configurable timeouts
- Security group with NFS access

### 7. Access Points

Four application-specific access points:

- **web_app**: Frontend application (UID 1000, permissions 0755)
- **api_backend**: Backend API (UID 2000, permissions 0750)
- **batch_jobs**: Batch processing (UID 3000, permissions 0770)
- **shared_data**: Shared storage (UID 4000, permissions 0775)

### 8. Monitoring

- Burst credit balance alarm (for bursting mode)
- Client connections alarm
- CloudWatch metrics integration

## Usage

### Prerequisites

1. AWS credentials configured
2. Terraform >= 1.5
3. Appropriate IAM permissions:
   - EC2 (VPC, subnets, security groups)
   - EFS (file system, mount targets, access points)
   - KMS (key creation and management)
   - CloudWatch (alarms)

### Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=test.tfvars

# Deploy the infrastructure
terraform apply -var-file=test.tfvars

# Clean up
terraform destroy -var-file=test.tfvars
```

## Variables Used

This example exercises **all 19 collection module variables**:

### File System (12 variables)

- ✅ `name` (via resource_names module)
- ✅ `environment`
- ✅ `file_system_name` (custom override)
- ✅ `availability_zone_name` (One Zone storage)
- ✅ `encrypted` (always true)
- ✅ `kms_key_id` (customer-managed key)
- ✅ `performance_mode`
- ✅ `throughput_mode`
- ✅ `provisioned_throughput_in_mibps`
- ✅ `lifecycle_policy` (all three transitions)
- ✅ `protection` (replication settings)
- ✅ `file_system_tags`

### Mount Targets (5 variables)

- ✅ `create_mount_targets`
- ✅ `mount_target_subnet_ids`
- ✅ `mount_target_security_group_ids`
- ✅ `mount_target_create_timeout`
- ✅ `mount_target_delete_timeout`

### Access Points (1 variable)

- ✅ `access_point_configurations` (4 access points)

### Shared (1 variable)

- ✅ `tags`

## Cost Considerations

This complete example creates:

- 1 EFS file system (Multi-AZ or One Zone)
- 3 mount targets (for Multi-AZ) or 1 (for One Zone)
- 4 access points
- 1 KMS key
- 2 CloudWatch alarms
- VPC and networking resources

**Estimated Monthly Cost (us-west-2)**:

- EFS Standard (Multi-AZ): ~$0.30/GB/month
- EFS One Zone: ~$0.16/GB/month
- KMS Key: $1/month
- CloudWatch Alarms: $0.20/alarm/month
- Data Transfer: Varies by usage

**Cost Optimization**:

- Set `use_one_zone_storage = true` to reduce costs by ~47%
- Use lifecycle policies to move data to IA (~$0.025/GB) and Archive (~$0.008/GB)
- Use `bursting` throughput mode for variable workloads

## One Zone vs Multi-AZ

### Multi-AZ (Default)

- High availability across availability zones
- Recommended for production workloads
- Higher cost (~$0.30/GB/month)

### One Zone

- Single availability zone storage
- 47% cost reduction (~$0.16/GB/month)
- Suitable for dev/test or non-critical workloads
- Enable by setting `use_one_zone_storage = true`

## Outputs

The example provides comprehensive outputs including:

- Resource names from naming module
- VPC and networking details
- KMS key information
- File system details (ID, ARN, DNS, size)
- Mount target information (per subnet)
- Access point details (per application)
- CloudWatch alarm ARNs
- Deployment summary

## Testing

This example is used for comprehensive integration testing:

```bash
# Run tests from the repository root
cd ../../tests/post_deploy_functional
go test -v -timeout 60m
```

## Additional Examples

For simpler usage, see:

- `../simple/` - Minimal viable EFS deployment

## References

- [EFS User Guide](https://docs.aws.amazon.com/efs/latest/ug/)
- [EFS Performance](https://docs.aws.amazon.com/efs/latest/ug/performance.html)
- [EFS Lifecycle Management](https://docs.aws.amazon.com/efs/latest/ug/lifecycle-management-efs.html)
- [Resource Naming Module](https://github.com/launchbynttdata/tf-launch-module_library-resource_name)

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
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | git::https://github.com/launchbynttdata/tf-launch-module_library-resource_name.git | 2.2.0 |
| <a name="module_efs"></a> [efs](#module\_efs) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.efs_burst_credit_balance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.efs_client_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_kms_alias.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key_policy.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key_policy) | resource |
| [aws_security_group.efs_mount_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.multi_az](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.one_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.complete](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | Logical product family for the resource naming module | `string` | n/a | yes |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | Logical product service for the resource naming module | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Instance environment number | `number` | `0` | no |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Instance resource number | `number` | `0` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_subnet_configs"></a> [subnet\_configs](#input\_subnet\_configs) | List of subnet configurations with CIDR blocks and AZ letter suffixes (e.g., 'a', 'b', 'c'). The full AZ name will be constructed as region + az\_letter. | <pre>list(object({<br/>    cidr_block = string<br/>    az_letter  = string<br/>  }))</pre> | n/a | yes |
| <a name="input_enabled_subnet_indices"></a> [enabled\_subnet\_indices](#input\_enabled\_subnet\_indices) | List of subnet indices (0-based) to create mount targets in.<br/>If null or empty, mount targets will be created in all subnets.<br/><br/>Example: [0, 2] creates mount targets only in the 1st and 3rd subnets.<br/>This allows testing subnet removal/addition without rebuilding existing mount targets. | `list(number)` | `null` | no |
| <a name="input_use_one_zone_storage"></a> [use\_one\_zone\_storage](#input\_use\_one\_zone\_storage) | Whether to use One Zone storage class instead of Multi-AZ (reduces cost) | `bool` | `false` | no |
| <a name="input_one_zone_availability_zone"></a> [one\_zone\_availability\_zone](#input\_one\_zone\_availability\_zone) | Specific availability zone for One Zone storage. If null, uses first available AZ | `string` | `null` | no |
| <a name="input_kms_deletion_window_days"></a> [kms\_deletion\_window\_days](#input\_kms\_deletion\_window\_days) | Number of days before KMS key deletion (7-30 days) | `number` | `10` | no |
| <a name="input_enable_kms_key_rotation"></a> [enable\_kms\_key\_rotation](#input\_enable\_kms\_key\_rotation) | Enable automatic KMS key rotation | `bool` | `true` | no |
| <a name="input_custom_file_system_name"></a> [custom\_file\_system\_name](#input\_custom\_file\_system\_name) | Custom name for the EFS file system. If null, uses resource\_names module output | `string` | `null` | no |
| <a name="input_performance_mode"></a> [performance\_mode](#input\_performance\_mode) | Performance mode: generalPurpose or maxIO | `string` | `"generalPurpose"` | no |
| <a name="input_throughput_mode"></a> [throughput\_mode](#input\_throughput\_mode) | Throughput mode: bursting, provisioned, or elastic | `string` | `"elastic"` | no |
| <a name="input_provisioned_throughput_in_mibps"></a> [provisioned\_throughput\_in\_mibps](#input\_provisioned\_throughput\_in\_mibps) | Provisioned throughput in MiB/s (only used when throughput\_mode = provisioned) | `number` | `null` | no |
| <a name="input_lifecycle_transition_to_ia"></a> [lifecycle\_transition\_to\_ia](#input\_lifecycle\_transition\_to\_ia) | When to transition files to Infrequent Access storage | `string` | `"AFTER_7_DAYS"` | no |
| <a name="input_lifecycle_transition_to_primary"></a> [lifecycle\_transition\_to\_primary](#input\_lifecycle\_transition\_to\_primary) | When to transition files back to primary storage | `string` | `"AFTER_1_ACCESS"` | no |
| <a name="input_lifecycle_transition_to_archive"></a> [lifecycle\_transition\_to\_archive](#input\_lifecycle\_transition\_to\_archive) | When to transition files to Archive storage | `string` | `"AFTER_90_DAYS"` | no |
| <a name="input_enable_replication_protection"></a> [enable\_replication\_protection](#input\_enable\_replication\_protection) | Enable replication protection configuration | `bool` | `false` | no |
| <a name="input_replication_overwrite_protection"></a> [replication\_overwrite\_protection](#input\_replication\_overwrite\_protection) | Replication overwrite protection setting: ENABLED, DISABLED, or REPLICATING | `string` | `"ENABLED"` | no |
| <a name="input_mount_target_create_timeout"></a> [mount\_target\_create\_timeout](#input\_mount\_target\_create\_timeout) | Timeout for creating mount targets | `string` | `"30m"` | no |
| <a name="input_mount_target_delete_timeout"></a> [mount\_target\_delete\_timeout](#input\_mount\_target\_delete\_timeout) | Timeout for deleting mount targets | `string` | `"15m"` | no |
| <a name="input_access_point_configurations"></a> [access\_point\_configurations](#input\_access\_point\_configurations) | Map of access point configurations for different applications | <pre>map(object({<br/>    posix_user = object({<br/>      uid            = number<br/>      gid            = number<br/>      secondary_gids = optional(list(number))<br/>    })<br/>    root_directory_path = string<br/>    root_directory_creation_info = optional(object({<br/>      owner_uid   = number<br/>      owner_gid   = number<br/>      permissions = string<br/>    }))<br/>    tags = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_burst_credit_alarm_threshold"></a> [burst\_credit\_alarm\_threshold](#input\_burst\_credit\_alarm\_threshold) | Threshold for burst credit balance alarm (in bytes) | `number` | `1000000000000` | no |
| <a name="input_client_connections_alarm_threshold"></a> [client\_connections\_alarm\_threshold](#input\_client\_connections\_alarm\_threshold) | Threshold for client connections alarm | `number` | `1000` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_name"></a> [resource\_name](#output\_resource\_name) | Standardized resource name from the naming module |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC created for the example |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the VPC |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | IDs of all subnets created |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the EFS mount target security group |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key used for EFS encryption |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key used for EFS encryption |
| <a name="output_kms_alias_name"></a> [kms\_alias\_name](#output\_kms\_alias\_name) | Name of the KMS key alias |
| <a name="output_file_system_id"></a> [file\_system\_id](#output\_file\_system\_id) | ID of the EFS file system |
| <a name="output_file_system_arn"></a> [file\_system\_arn](#output\_file\_system\_arn) | ARN of the EFS file system |
| <a name="output_file_system_dns_name"></a> [file\_system\_dns\_name](#output\_file\_system\_dns\_name) | DNS name of the EFS file system |
| <a name="output_file_system_creation_token"></a> [file\_system\_creation\_token](#output\_file\_system\_creation\_token) | Creation token of the EFS file system |
| <a name="output_file_system_availability_zone_id"></a> [file\_system\_availability\_zone\_id](#output\_file\_system\_availability\_zone\_id) | Availability zone ID for One Zone storage (null for Multi-AZ) |
| <a name="output_file_system_availability_zone_name"></a> [file\_system\_availability\_zone\_name](#output\_file\_system\_availability\_zone\_name) | Availability zone name for One Zone storage (null for Multi-AZ) |
| <a name="output_file_system_name"></a> [file\_system\_name](#output\_file\_system\_name) | Name of the file system |
| <a name="output_mount_target_ids"></a> [mount\_target\_ids](#output\_mount\_target\_ids) | IDs of all mount targets |
| <a name="output_mount_target_dns_names"></a> [mount\_target\_dns\_names](#output\_mount\_target\_dns\_names) | DNS names of all mount targets |
| <a name="output_mount_target_network_interface_ids"></a> [mount\_target\_network\_interface\_ids](#output\_mount\_target\_network\_interface\_ids) | Network interface IDs of all mount targets |
| <a name="output_mount_target_availability_zone_names"></a> [mount\_target\_availability\_zone\_names](#output\_mount\_target\_availability\_zone\_names) | Availability zones of all mount targets |
| <a name="output_mount_target_availability_zone_ids"></a> [mount\_target\_availability\_zone\_ids](#output\_mount\_target\_availability\_zone\_ids) | Availability zone IDs of all mount targets |
| <a name="output_mount_target_file_system_arns"></a> [mount\_target\_file\_system\_arns](#output\_mount\_target\_file\_system\_arns) | ARNs of the file system for each mount target |
| <a name="output_mount_target_owner_ids"></a> [mount\_target\_owner\_ids](#output\_mount\_target\_owner\_ids) | AWS account IDs of the mount target owners |
| <a name="output_mount_target_az_dns_names"></a> [mount\_target\_az\_dns\_names](#output\_mount\_target\_az\_dns\_names) | AZ-specific DNS names for mount targets |
| <a name="output_access_point_ids"></a> [access\_point\_ids](#output\_access\_point\_ids) | Map of access point names to IDs |
| <a name="output_access_point_arns"></a> [access\_point\_arns](#output\_access\_point\_arns) | Map of access point names to ARNs |
| <a name="output_access_point_file_system_ids"></a> [access\_point\_file\_system\_ids](#output\_access\_point\_file\_system\_ids) | Map of access point names to file system IDs |
| <a name="output_access_point_owner_ids"></a> [access\_point\_owner\_ids](#output\_access\_point\_owner\_ids) | Map of access point names to owner IDs |
| <a name="output_access_point_posix_users"></a> [access\_point\_posix\_users](#output\_access\_point\_posix\_users) | Map of access point names to POSIX user configurations |
| <a name="output_access_point_root_directories"></a> [access\_point\_root\_directories](#output\_access\_point\_root\_directories) | Map of access point names to root directory configurations |
| <a name="output_access_point_tags"></a> [access\_point\_tags](#output\_access\_point\_tags) | Map of access point names to their tags |
| <a name="output_burst_credit_alarm_arn"></a> [burst\_credit\_alarm\_arn](#output\_burst\_credit\_alarm\_arn) | ARN of the burst credit balance alarm (if created) |
| <a name="output_client_connections_alarm_arn"></a> [client\_connections\_alarm\_arn](#output\_client\_connections\_alarm\_arn) | ARN of the client connections alarm |
| <a name="output_deployment_info"></a> [deployment\_info](#output\_deployment\_info) | Summary of the deployed EFS configuration |
<!-- END_TF_DOCS -->
