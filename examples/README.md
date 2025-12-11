# Examples Directory

This directory contains example implementations demonstrating how to use the **collection module**. Examples serve multiple purposes:

1. **Documentation**: Show users how to configure and use the collection module
2. **Testing**: Provide test cases for automated integration testing
3. **Validation**: Verify the collection module and its sub-modules work correctly

## Collection Module Examples

**Important:** These examples demonstrate **collection module** usage, not primitive module usage. The key differences:

- Examples create **supporting infrastructure** (VPC, subnets, security groups)
- Examples call the **collection module** (which orchestrates primitive modules)
- The collection module internally calls **primitive modules**
- Primitive modules create the actual **AWS resources**

### Example Architecture

```text
Example (examples/simple/main.tf)
  ├─→ Creates: VPC, Subnets, Security Groups
  └─→ Calls: EFS Collection Module (../../main.tf)
      ├─→ Calls: efs_file_system Primitive → Creates EFS File System
      ├─→ Calls: efs_mount_target Primitive → Creates Mount Targets (one per subnet)
      └─→ Calls: efs_access_point Primitive → Creates Access Points
```

## Example Types

### Simple Example (`simple/`)

The simple example demonstrates the **minimum viable configuration** required to use the collection module. It should:

- Use only required variables for the EFS collection module
- Provide sensible defaults for optional variables
- Include minimal supporting infrastructure (VPC, 2 subnets, security group with NFS port 2049)
- Create a basic EFS file system with mount targets and 2 access points
- Be quick to deploy and destroy
- Serve as a starting point for new users

**What it demonstrates:**

- Creating supporting infrastructure externally (VPC, subnets, security group)
- Configuring basic EFS file system settings (encryption, performance mode)
- Creating mount targets in multiple subnets for high availability
- Setting up multiple access points with different POSIX user configurations
- Retrieving outputs from the EFS collection module

**When to use:** First-time users, quick validation, basic collection module functionality testing

### Complete Example (`complete/`)

The complete example demonstrates a **comprehensive configuration** that exercises most or all collection module features. It should:

- Use most available variables and EFS configuration options
- Demonstrate advanced EFS patterns (One Zone storage, custom KMS encryption)
- Create comprehensive monitoring with CloudWatch alarms
- Show lifecycle policies for cost optimization (IA and Archive storage tiers)
- Demonstrate resource naming module integration
- Include 4 different access points with varied permissions

**What it demonstrates:**

- Complex EFS configuration with customer-managed KMS encryption
- Multi-AZ vs One Zone storage options for cost optimization
- Advanced lifecycle policies (transition to IA, Archive, and back to primary)
- Provisioned throughput configuration for predictable performance
- CloudWatch alarms for burst credits and client connections
- Resource naming module for standardized naming conventions

**When to use:** Testing all collection module features, understanding advanced orchestration, production-ready patterns

## Directory Structure

Each example should contain the following files:

```text
example_name/
├── README.md           # Example-specific documentation
├── main.tf            # Primary resource definitions and module invocation
├── variables.tf       # Input variable definitions
├── outputs.tf         # Output value definitions
├── locals.tf          # Local values (if needed)
├── provider.tf        # Provider configuration
├── versions.tf        # Terraform and provider version constraints
└── test.tfvars        # Example variable values for testing
```

## Example README Structure

Each example's README should include:

1. **Purpose**: Brief description of what the example demonstrates
2. **Resources Created**: List of AWS resources that will be created
3. **Prerequisites**: Any requirements (e.g., existing resources, permissions)
4. **Usage**: Code snippet showing module invocation
5. **Inputs**: Table of input variables
6. **Outputs**: Table of output values
7. **How to Run**: Step-by-step deployment instructions
8. **Cleanup**: Instructions for destroying resources

## Running Examples

### Initial Setup

```bash
cd examples/<example_name>
terraform init
```

### Plan and Apply

```bash
# Review changes
terraform plan -var-file=test.tfvars

# Apply changes
terraform apply -var-file=test.tfvars

# Or combine plan and apply
terraform plan -var-file=test.tfvars -out=tfplan
terraform apply tfplan
```

### Cleanup

```bash
terraform destroy -var-file=test.tfvars
```

## Testing with Examples

The automated tests in the `tests/` directory use these examples as test fixtures. Tests typically:

1. Deploy the example using Terratest
2. Verify outputs and resource attributes
3. Run functional tests against deployed resources
4. Clean up resources after testing

See the [tests/README.md](../tests/README.md) for more information on running tests.

## Best Practices

### Module Reference

Examples should reference the module using a relative path:

```hcl
module "example" {
  source = "../.."  # Points to root module directory

  # Configuration...
}
```

### Variable Files

- **DO** provide a `test.tfvars` file with example values
- **DO** use realistic but non-sensitive values
- **DON'T** commit actual credentials or sensitive data
- **DO** document any variables that users need to customize

### Supporting Resources

**Critical for Collection Modules:** Examples **must** create supporting AWS resources externally because collection modules only orchestrate primitive modules and don't create infrastructure directly.

Supporting resources (VPC, subnets, security groups) should:

- Be defined directly in the example's `main.tf` (not as separate modules)
- Be created **before** the collection module is invoked
- Use reasonable defaults suitable for testing
- Be clearly documented in the example README
- Be minimal but sufficient to demonstrate the collection module
- Pass IDs/ARNs to the collection module as input variables

**Example pattern:**

```hcl
# Create supporting infrastructure
resource "aws_vpc" "example" { /* ... */ }
resource "aws_subnet" "example" { /* ... */ }

# Call collection module with infrastructure references
module "collection" {
  source    = "../.."
  vpc_id    = aws_vpc.example.id
  subnet_ids = aws_subnet.example[*].id
}
```

### Documentation

- Keep example READMEs up-to-date with code changes
- Include terraform-docs generated documentation
- Provide clear deployment and cleanup instructions
- Document any prerequisites or assumptions

## Adding New Examples

When adding a new example:

1. Create a new directory under `examples/`
2. Include all required files (see Directory Structure above)
3. Write a comprehensive README
4. Test the example manually before committing
5. Consider adding automated tests for the example
6. Update this README if adding a new example type

## Common Patterns for Collection Modules

### Supporting Infrastructure + Collection Module

The standard pattern for collection module examples:

```hcl
# 1. Create supporting infrastructure
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  count             = 3
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# 2. Call EFS collection module
module "efs" {
  source     = "../.."
  name        = "my-efs"
  environment = "dev"

  # File system configuration
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Mount targets
  create_mount_targets = true
  mount_target_subnet_ids = {
    for idx, subnet in aws_subnet.example : "subnet-${idx + 1}" => subnet.id
  }
  mount_target_security_group_ids = [aws_security_group.efs.id]

  # Access points
  access_point_configurations = {
    app1 = {
      posix_user = { uid = 1000, gid = 1000 }
      root_directory_path = "/app1"
    }
  }
}
```

### Conditional Mount Target Creation

Demonstrate enabling/disabling mount target creation:

```hcl
module "efs" {
  source = "../.."

  name        = "my-efs"
  environment = "dev"

  # File system configuration
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  # Conditionally create mount targets
  create_mount_targets = var.enable_mount_targets
  mount_target_subnet_ids = var.enable_mount_targets ? {
    for idx, subnet in aws_subnet.example : "subnet-${idx + 1}" => subnet.id
  } : {}
  mount_target_security_group_ids = [aws_security_group.efs.id]

  # Access points (optional - can be empty map)
  access_point_configurations = var.access_point_configs
}
```

### Aggregated Outputs

Show how to access outputs from the EFS collection module:

```hcl
# File system outputs
output "file_system_id" {
  description = "EFS file system ID"
  value       = module.efs.file_system_id
}

output "file_system_dns_name" {
  description = "DNS name for mounting"
  value       = module.efs.file_system_dns_name
}

# Mount target outputs (map of all mount targets)
output "mount_target_ids" {
  description = "All mount target IDs"
  value       = module.efs.mount_target_ids
}

# Access point outputs (map of all access points)
output "access_point_ids" {
  description = "All access point IDs"
  value       = module.efs.access_point_ids
}
```

### External Dependencies

Reference existing resources when needed:

```hcl
data "aws_vpc" "existing" {
  default = true
}

data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

data "aws_security_group" "existing_efs_sg" {
  name = "existing-efs-security-group"
}

module "efs" {
  source      = "../.."
  name        = "my-efs"
  environment = "prod"

  # Use existing infrastructure
  create_mount_targets            = true
  mount_target_subnet_ids         = { for idx, id in data.aws_subnets.existing.ids : "subnet-${idx + 1}" => id }
  mount_target_security_group_ids = [data.aws_security_group.existing_efs_sg.id]

  access_point_configurations = {
    app = {
      posix_user          = { uid = 1000, gid = 1000 }
      root_directory_path = "/app"
    }
  }
}
```
