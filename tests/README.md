# Tests Directory

This directory contains automated integration tests for the **collection module** using [Terratest](https://terratest.gruntwork.io/), a Go-based testing framework.

## Overview

Automated tests ensure the collection module works correctly by:

1. **Deploying** the collection module using example configurations
2. **Validating** that the collection module correctly orchestrates primitive modules
3. **Testing** outputs from multiple sub-modules
4. **Verifying** aggregated outputs across all sub-modules
5. **Cleaning up** all resources after testing

## Collection Module Testing

**Important:** These tests validate a **collection module**, not a primitive module. The key differences:

- Tests deploy examples that create supporting infrastructure (VPC, subnets, security groups)
- Tests call the collection module, which internally orchestrates primitive modules
- Tests validate outputs from **multiple sub-modules** through the collection module
- Tests verify **aggregated outputs** and coordination logic
- Tests do NOT directly create AWS resources—the primitive modules do that

## Directory Structure

```text
tests/
├── README.md                          # This file
├── post_deploy_functional/            # Tests that modify resources
│   └── main_test.go                   # Primary test entry point
├── post_deploy_functional_readonly/   # Tests that only read/verify
│   └── main_test.go                   # Read-only test entry point
└── testimpl/                          # Shared test implementation
    ├── test_impl.go                   # Test logic and assertions
    └── types.go                       # Test type definitions
```

## Test Categories

### Post-Deploy Functional Tests (`post_deploy_functional/`)

These tests **deploy and modify** resources to validate the complete lifecycle:

- **Example**: Uses `examples/complete` for comprehensive testing
- **Deployment**: Creates actual AWS resources via Terraform apply
- **Modifications**: Tests dynamic configuration changes (e.g., subnet index cycling)
- **Validation**: Uses AWS SDK to verify resource state at each phase
- **Phases**:
  1. Deploy with all subnets enabled
  2. Remove specific subnets and validate stable resources
  3. Modify subnet configuration and validate no rebuilds
  4. Full cleanup and teardown

**Use when:** Testing full deployment lifecycle, resource updates, and AWS API validation

**EFS Collection Example Test Flow:**

1. Deploy EFS with mount targets in subnets A, B, C
2. Update to remove subnet B (mount targets in A, C remain stable)
3. Update to remove A and restore B (mount targets in B, C remain stable)
4. Validate with AWS SDK after each phase
5. Destroy all resources

### Post-Deploy Functional Read-Only Tests (`post_deploy_functional_readonly/`)

These tests **validate plans without deploying** resources:

- **Example**: Uses `examples/simple` for fast validation
- **Execution**: Runs `terraform init` and `terraform plan` only
- **Validation**: Verifies configuration is syntactically correct
- **Speed**: Much faster than functional tests (no resource creation)
- **Safety**: No AWS costs, no resource cleanup needed

**Use when:** Validating configuration syntax, testing in restricted environments, or quick validation cycles

## Test Implementation Pattern

Tests follow a standard pattern for collection modules:

1. **Setup** (`testimpl/types.go`): Define test context and configuration
2. **Deploy** (`main_test.go`): Use Terratest to deploy the example
   - Example creates supporting infrastructure (VPC, subnets, security groups)
   - Example calls the collection module
   - Collection module calls primitive modules
3. **Validate** (`testimpl/test_impl.go`): Run assertions against collection module outputs
   - Validate outputs from each sub-module
   - Validate aggregated outputs across all sub-modules
   - Verify coordination logic between sub-modules
4. **Cleanup**: Terratest automatically destroys resources (unless configured otherwise)

### Collection Module Test Structure

```text
Test Execution Flow:
1. Terratest deploys example (examples/simple/main.tf)
2. Example creates: VPC, Subnets, Security Groups
3. Example calls: Collection Module (../../main.tf)
4. Collection Module calls: Primitive Module 1, 2, 3
5. Primitive Modules create: AWS Resources
6. Tests validate: Collection Module outputs (aggregated from all sub-modules)
7. Tests validate: Individual sub-module outputs
8. Terratest destroys: All resources
```

## Running Tests

### Prerequisites

- Go >= 1.21 installed
- AWS credentials configured
- Terraform >= 1.5 installed
- Appropriate AWS permissions to create/destroy resources

### Run All Tests

```bash
# From the repository root
make check
```

### Run Specific Test Suite

```bash
# Run functional tests (uses complete example)
cd tests/post_deploy_functional
go test -v -timeout 30m

# Run read-only tests (uses simple example)
cd tests/post_deploy_functional_readonly
go test -v -timeout 30m
```

### Test Configuration

Tests use different examples based on their purpose:

- **post_deploy_functional_readonly**: Uses `examples/simple` for plan-only validation without deployment
- **post_deploy_functional**: Uses `examples/complete` for full deployment with dynamic configuration testing

The functional test includes multi-phase testing to validate:

- Initial deployment with all resources
- Dynamic configuration updates (e.g., `enabled_subnet_indices`)
- Stable resource keys preventing unnecessary rebuilds
- AWS API validation at each phase

To test a different example, modify the test configuration in `main_test.go`:

```go
testConfigsExamplesFolderDefault = "../../examples/simple"  // or "../../examples/complete"
```

### Test Flags

```bash
# Run with verbose output
go test -v

# Set custom timeout (default is 10 minutes, increase for complex deployments)
go test -timeout 45m

# Run specific test function
go test -v -run TestFunctionalityName

# Keep resources after test for debugging
go test -v -timeout 30m -args -terraform-keep-resources
```

## Important: Do Not Run from Test Directory

**❌ DO NOT run tests directly from the `tests/` directory**

Tests are designed to be run from the **examples directory** where the Terraform configuration exists. The test code references the example directory and deploys those configurations.

**Correct workflow:**

```bash
# From repository root
make check

# OR from specific test directory
cd tests/post_deploy_functional
go test -v -timeout 30m
```

The test code will:

1. Reference the example directory (e.g., `../../examples/simple`)
2. Deploy that example using Terratest
3. Run validations against deployed resources
4. Clean up resources

## Writing New Tests for Collection Modules

### 1. Add Test Logic to `testimpl/test_impl.go`

**Important:** Test the collection module's outputs, which aggregate data from primitive modules.

```go
func TestNewSubModule(t *testing.T, ctx testTypes.TestContext) {
    // Get outputs from collection module
    terraformOptions := ctx.TerratestTerraformOptions()

    // Test EFS file system outputs
    t.Run("TestFileSystemOutputs", func(t *testing.T) {
        fileSystemId := terraform.Output(t, terraformOptions, "file_system_id")
        assert.NotEmpty(t, fileSystemId, "File system ID should not be empty")

        fileSystemDnsName := terraform.Output(t, terraformOptions, "file_system_dns_name")
        assert.NotEmpty(t, fileSystemDnsName, "File system DNS name should not be empty")
        assert.Contains(t, fileSystemDnsName, ".efs.", "DNS name should contain .efs.")
    })

    // Test mount target outputs
    t.Run("TestMountTargetOutputs", func(t *testing.T) {
        mountTargetIds := terraform.OutputMap(t, terraformOptions, "mount_target_ids")
        assert.NotEmpty(t, mountTargetIds, "Mount target IDs should not be empty")
        assert.GreaterOrEqual(t, len(mountTargetIds), 1, "Should have at least one mount target")
    })

    // Test access point outputs
    t.Run("TestAccessPointOutputs", func(t *testing.T) {
        accessPointIds := terraform.OutputMap(t, terraformOptions, "access_point_ids")
        assert.NotEmpty(t, accessPointIds, "Access point IDs should not be empty")
    })

    // Test aggregated outputs
    t.Run("TestAggregatedOutputs", func(t *testing.T) {
        allResourceArns := terraform.OutputList(t, terraformOptions, "all_resource_arns")
        assert.NotEmpty(t, allResourceArns, "Aggregated resource ARNs should not be empty")

        // Verify all EFS components are represented
        // Should include file system ARN + mount target ARNs + access point ARNs
        assert.GreaterOrEqual(t, len(allResourceArns), 3, "Should have ARNs from file system, mount targets, and access points")
    })

    // Optional: Validate AWS EFS resources created by primitive modules
    t.Run("TestEFSResourcesViaSDK", func(t *testing.T) {
        awsConfig := GetAWSConfig(t)
        efsClient := efs.NewFromConfig(awsConfig)

        fileSystemId := terraform.Output(t, terraformOptions, "file_system_id")

        // Verify file system exists and has correct configuration
        result, err := efsClient.DescribeFileSystems(context.TODO(), &efs.DescribeFileSystemsInput{
            FileSystemId: aws.String(fileSystemId),
        })
        require.NoError(t, err)
        require.Len(t, result.FileSystems, 1)
        assert.Equal(t, "encrypted", *result.FileSystems[0].Encrypted)
    })
}
```

### 2. Call Test from `main_test.go`

```go
func TestFunctionalFeature(t *testing.T) {
    ctx := createContext(t)
    testimpl.TestNewFeature(t, ctx)
}
```

### 3. Use Sub-tests for Organization

```go
t.Run("GroupName", func(t *testing.T) {
    t.Run("SpecificTest1", func(t *testing.T) {
        // Test logic
    })
    t.Run("SpecificTest2", func(t *testing.T) {
        // Test logic
    })
})
```

## Common Test Patterns for Collection Modules

### Validate Collection Module Outputs

```go
terraformOptions := ctx.TerratestTerraformOptions()

// Validate EFS file system outputs
fileSystemId := terraform.Output(t, terraformOptions, "file_system_id")
assert.NotEmpty(t, fileSystemId, "File system ID should not be empty")
assert.True(t, strings.HasPrefix(fileSystemId, "fs-"), "File system ID should start with fs-")

// Validate mount target outputs
mountTargetIds := terraform.OutputMap(t, terraformOptions, "mount_target_ids")
assert.NotEmpty(t, mountTargetIds, "Mount target IDs should not be empty")

// Validate aggregated outputs across all EFS components
allResourceArns := terraform.OutputList(t, terraformOptions, "all_resource_arns")
assert.NotEmpty(t, allResourceArns, "Aggregated resource ARNs should not be empty")

// Validate connection info
connectionInfo := terraform.OutputMap(t, terraformOptions, "connection_info")
assert.Contains(t, connectionInfo, "dns_name", "Connection info should include DNS name")
assert.Contains(t, connectionInfo, "file_system_id", "Connection info should include file system ID")

```

### Test Mount Target Creation

```go
// Test conditional mount target creation
t.Run("TestConditionalMountTargets", func(t *testing.T) {
    // When create_mount_targets = false
    mountTargetIds := terraform.OutputMap(t, terraformOptions, "mount_target_ids")
    if createMountTargets {
        assert.NotEmpty(t, mountTargetIds, "Mount targets should be created")
        // Verify one mount target per subnet
        expectedCount := len(subnetIds)
        assert.Equal(t, expectedCount, len(mountTargetIds), "Should have one mount target per subnet")
    } else {
        assert.Empty(t, mountTargetIds, "Mount targets should not be created")
    }
})
```

### Validate AWS Resources

```go
// Get AWS config
awsConfig := GetAWSConfig(t)

// Create EFS client
efsClient := efs.NewFromConfig(awsConfig)

// Query file system
fileSystemId := terraform.Output(t, terraformOptions, "file_system_id")
result, err := efsClient.DescribeFileSystems(context.TODO(), &efs.DescribeFileSystemsInput{
    FileSystemId: aws.String(fileSystemId),
})
require.NoError(t, err)
require.Len(t, result.FileSystems, 1)

// Validate file system attributes
fs := result.FileSystems[0]
assert.True(t, *fs.Encrypted, "File system should be encrypted")
assert.Equal(t, "generalPurpose", string(fs.PerformanceMode), "Should use general purpose performance mode")
assert.Equal(t, "available", string(fs.LifeCycleState), "File system should be available")
```

### Test EFS Component Coordination

```go
t.Run("TestEFSComponentCoordination", func(t *testing.T) {
    // Validate that mount targets and access points reference the same file system
    fileSystemId := terraform.Output(t, terraformOptions, "file_system_id")

    // Get mount target file system ARNs
    mountTargetArns := terraform.OutputMap(t, terraformOptions, "mount_target_file_system_arns")

    // All mount targets should reference the same file system
    for mtName, arn := range mountTargetArns {
        assert.Contains(t, arn, fileSystemId,
            "Mount target %s should reference the correct file system", mtName)
    }

    // Get access point file system IDs
    accessPointFsIds := terraform.OutputMap(t, terraformOptions, "access_point_file_system_ids")

    // All access points should reference the same file system
    for apName, fsId := range accessPointFsIds {
        assert.Equal(t, fileSystemId, fsId,
            "Access point %s should reference the correct file system", apName)
    }
})

t.Run("TestAggregatedData", func(t *testing.T) {
    // Validate aggregated outputs combine data from all EFS components
    allResourceArns := terraform.OutputList(t, terraformOptions, "all_resource_arns")
    fileSystemArn := terraform.Output(t, terraformOptions, "file_system_arn")

    // Aggregated list should contain the file system ARN
    assert.Contains(t, allResourceArns, fileSystemArn,
        "Aggregated ARNs should include file system ARN")

    // Should also contain mount target and access point ARNs
    mountTargetArns := terraform.OutputMap(t, terraformOptions, "mount_target_file_system_arns")
    for _, arn := range mountTargetArns {
        assert.Contains(t, allResourceArns, arn,
            "Aggregated ARNs should include mount target ARNs")
    }
})
```

## Best Practices

### Test Design

1. **Test One Thing**: Each test should verify a specific behavior
2. **Use Sub-tests**: Group related assertions using `t.Run()`
3. **Descriptive Names**: Use clear, descriptive test names
4. **Independent Tests**: Tests should not depend on each other's state
5. **Clean Assertions**: Use meaningful assertion messages

### Test Execution

1. **Set Appropriate Timeouts**: Complex deployments may need longer timeouts
2. **Handle Errors Gracefully**: Use `require` for critical assertions, `assert` for non-critical
3. **Clean Up Resources**: Ensure Terratest cleanup runs even if tests fail
4. **Test in Isolation**: Run tests in separate AWS accounts/regions when possible

### AWS SDK Usage

1. **Reuse Clients**: Create AWS clients once and reuse them
2. **Handle Pagination**: Use pagination when listing resources
3. **Check Errors**: Always check AWS SDK errors
4. **Use Context**: Pass context for timeout control

### Debugging Failed Tests

1. **Enable Verbose Output**: Use `-v` flag
2. **Increase Timeout**: Use `-timeout` flag for slow deployments
3. **Keep Resources**: Use `-args -terraform-keep-resources` to inspect failed state
4. **Check AWS Console**: Verify resource state in AWS console
5. **Review Terraform State**: Use `terraform show` on the example directory

## CI/CD Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    make check
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_DEFAULT_REGION: us-east-1
```

## Troubleshooting

### Tests Fail with "command not found: terraform"

**Solution**: Ensure Terraform is installed and in PATH:

```bash
terraform version
```

### Tests Timeout

**Solution**: Increase timeout value:

```bash
go test -timeout 60m
```

### AWS Credential Errors

**Solution**: Configure AWS credentials:

```bash
aws configure
# OR
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_DEFAULT_REGION=us-east-1
```

### Resources Not Cleaned Up

**Solution**: Manually destroy the example:

```bash
cd examples/simple
terraform destroy -auto-approve
```

### Import Errors

**Solution**: Run `go mod download` and `go mod tidy`:

```bash
cd tests/post_deploy_functional
go mod download
go mod tidy
```

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [AWS SDK for Go v2](https://aws.github.io/aws-sdk-go-v2/)
- [Go Testing Package](https://pkg.go.dev/testing)
- [Testify Assert](https://pkg.go.dev/github.com/stretchr/testify/assert)
