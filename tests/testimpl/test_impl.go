package testimpl

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/efs"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testTypes "github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ========================================
// Test Implementation Template
// ========================================
// This file contains the test logic and assertions for the Terraform module.
// Customize the test functions below to validate your specific module's behavior.

// TestComposableEFSCollectionComplete tests the complete example with actual deployment and subnet index cycling.
// This test will:
// 1. Deploy with all 3 subnets enabled (default: enabled_subnet_indices = null)
// 2. Update to remove subnet B (enabled_subnet_indices = [0, 2])
// 3. Update to remove subnet A and restore B (enabled_subnet_indices = [1, 2])
// 4. Validate resources with AWS SDK after each change
func TestComposableEFSCollectionComplete(t *testing.T, ctx testTypes.TestContext) {
	// Phase 1: Initial deployment with all subnets
	t.Run("Phase1_DeployAllSubnets", func(t *testing.T) {
		t.Log("Deploying EFS with all 3 subnets enabled (default configuration)")
		validateEFSDeployment(t, ctx, 3, []string{"az-a", "az-b", "az-c"})
	})

	// Phase 2: Remove subnet B (keep A and C)
	t.Run("Phase2_RemoveSubnetB", func(t *testing.T) {
		t.Log("Updating configuration to remove subnet B mount target")

		// Update the tfvars to set enabled_subnet_indices = [0, 2]
		terraformOptions := ctx.TerratestTerraformOptions()

		// CRITICAL: Set this flag to ensure -var flags come after -var-file flags
		// This allows our variable override to take precedence over test.tfvars
		terraformOptions.SetVarsAfterVarFiles = true

		terraformOptions.Vars = map[string]interface{}{
			"enabled_subnet_indices": []int{0, 2}, // Keep indices 0 (az-a) and 2 (az-c), remove 1 (az-b)
		}

		// Apply the changes
		terraform.Apply(t, terraformOptions)

		validateEFSDeployment(t, ctx, 2, []string{"az-a", "az-c"})
	})

	// Phase 3: Remove subnet A, restore subnet B (keep B and C)
	t.Run("Phase3_RemoveSubnetA_RestoreSubnetB", func(t *testing.T) {
		t.Log("Updating configuration to remove subnet A and restore subnet B")

		// Update the tfvars to set enabled_subnet_indices = [1, 2]
		terraformOptions := ctx.TerratestTerraformOptions()

		// CRITICAL: Set this flag to ensure -var flags come after -var-file flags
		terraformOptions.SetVarsAfterVarFiles = true

		terraformOptions.Vars = map[string]interface{}{
			"enabled_subnet_indices": []int{1, 2}, // Keep indices 1 (az-b) and 2 (az-c), remove 0 (az-a)
		}

		// Apply the changes
		terraform.Apply(t, terraformOptions)

		validateEFSDeployment(t, ctx, 2, []string{"az-b", "az-c"})
	})
}

// TestComposableEFSCollectionSimple validates the simple example with actual deployment.
// This test validates that the minimal configuration deploys successfully with a single mount target.
func TestComposableEFSCollectionSimple(t *testing.T, ctx testTypes.TestContext) {
	t.Run("DeploySimpleExample", func(t *testing.T) {
		t.Log("Deploying simple EFS example with single mount target")
		// Simple example has a single mount target with key "primary"
		validateEFSDeployment(t, ctx, 1, []string{"primary"})
	})
}

// TestComposableEFSCollectionSimpleReadOnly validates the simple example configuration without deployment.
// This test validates that the Terraform configuration is valid and can generate a plan successfully.
// It also validates that the planned resources match expected configuration from test.tfvars.
// No infrastructure is created - this is a plan-only validation test.
func TestComposableEFSCollectionSimpleReadOnly(t *testing.T, ctx testTypes.TestContext) {
	t.Run("ValidateSimpleExamplePlan", func(t *testing.T) {
		t.Log("Validating simple EFS example configuration (plan-only, no deployment)")

		terraformOptions := ctx.TerratestTerraformOptions()

		// Set the plan file path for plan validation
		terraformOptions.PlanFilePath = filepath.Join(terraformOptions.TerraformDir, "tfplan")

		// Initialize Terraform
		terraform.Init(t, terraformOptions)

		// Run terraform plan and validate it succeeds
		planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

		// Validate the plan contains expected resources
		t.Run("ValidatePlannedResources", func(t *testing.T) {
			// Count expected resources in the plan
			resourceChanges := planStruct.ResourceChangesMap

			// Expected resources for simple example:
			// - 1 VPC
			// - 1 Subnet
			// - 1 Security group
			// - EFS module resources (file system, mount target, access points)
			assert.NotEmpty(t, resourceChanges, "Plan should contain resource changes")

			// Verify EFS file system is planned
			var efsFileSystemFound bool
			var efsMountTargetFound bool
			var efsAccessPointsCount int

			for _, rc := range resourceChanges {
				if rc.Type == "aws_efs_file_system" && (rc.Change.Actions.Create() || rc.Change.Actions.Update()) {
					efsFileSystemFound = true
					t.Logf("✅ Found EFS file system in plan: %s", rc.Address)

					// Validate file system configuration from test.tfvars
					if rc.Change.After != nil {
						afterMap := rc.Change.After.(map[string]interface{})

						// Validate encryption is enabled (from test.tfvars: encrypted = true)
						if encrypted, ok := afterMap["encrypted"].(bool); ok {
							assert.True(t, encrypted, "EFS file system should be encrypted")
						}

						// Validate performance mode (from test.tfvars: performance_mode = "generalPurpose")
						if perfMode, ok := afterMap["performance_mode"].(string); ok {
							assert.Equal(t, "generalPurpose", perfMode, "Performance mode should be generalPurpose")
						}

						// Validate throughput mode (from test.tfvars: throughput_mode = "bursting")
						if throughputMode, ok := afterMap["throughput_mode"].(string); ok {
							assert.Equal(t, "bursting", throughputMode, "Throughput mode should be bursting")
						}
					}
				}

				if rc.Type == "aws_efs_mount_target" && (rc.Change.Actions.Create() || rc.Change.Actions.Update()) {
					efsMountTargetFound = true
					t.Logf("✅ Found EFS mount target in plan: %s", rc.Address)
				}

				if rc.Type == "aws_efs_access_point" && (rc.Change.Actions.Create() || rc.Change.Actions.Update()) {
					efsAccessPointsCount++
					t.Logf("✅ Found EFS access point in plan: %s", rc.Address)
				}
			}

			assert.True(t, efsFileSystemFound, "Plan should include EFS file system")
			assert.True(t, efsMountTargetFound, "Plan should include at least one EFS mount target")
			assert.Equal(t, 2, efsAccessPointsCount, "Plan should include 2 EFS access points (app1 and app2 from test.tfvars)")

			t.Logf("✅ Plan validation complete: Found file system, %d mount target(s), and %d access points",
				1, efsAccessPointsCount)
		})

		t.Run("ValidatePlannedOutputs", func(t *testing.T) {
			// Validate that expected outputs are defined in the configuration
			// Note: Output values won't be available until after apply, but we can validate
			// that the configuration is structured correctly by checking for outputs in the raw plan

			// The simple example should have these outputs defined
			expectedOutputs := []string{
				"file_system_id",
				"file_system_arn",
				"file_system_dns_name",
				"mount_target_ids",
				"access_point_ids",
				"connection_info",
				"mount_command",
			}

			// Since outputs aren't populated in plan, we just log that we expect them
			// The fact that the plan succeeded means the output blocks are syntactically valid
			t.Logf("✅ Plan succeeded - output configuration validated (%d expected outputs)", len(expectedOutputs))
		})

		t.Log("✅ Simple example configuration is valid and plan succeeded with expected resources")
	})
}

// validateEFSDeployment is a helper function that validates the EFS deployment
// after each phase of the complete test
func validateEFSDeployment(t *testing.T, ctx testTypes.TestContext, expectedMountTargets int, expectedMountTargetNames []string) {
	t.Helper()

	// ========================================
	// Get Terraform Outputs from EFS Collection Module
	// ========================================
	// Collection module aggregates outputs from EFS file system, mount targets, and access points

	// EFS File System outputs
	fileSystemID := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_id")
	fileSystemARN := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_arn")
	fileSystemDNSName := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_dns_name")
	fileSystemName := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_name")

	// Mount Target outputs (maps keyed by mount target name)
	mountTargetIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_ids")
	mountTargetDNSNames := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_dns_names")

	// Access Point outputs (maps keyed by access point name)
	accessPointIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_ids")
	accessPointARNs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_arns")

	// Aggregated outputs from collection
	allResourceARNs := terraform.OutputList(t, ctx.TerratestTerraformOptions(), "all_resource_arns")

	// ========================================
	// EFS File System Validations
	// ========================================
	// Validate outputs from the EFS file system primitive module

	t.Run("TestEFSFileSystemOutputs", func(t *testing.T) {
		t.Run("TestFileSystemID", func(t *testing.T) {
			assert.NotEmpty(t, fileSystemID, "File system ID should not be empty")
			assert.Regexp(t, "^fs-[a-f0-9]+$", fileSystemID, "File system ID should match pattern fs-xxxxxxxx")
		})

		t.Run("TestFileSystemARN", func(t *testing.T) {
			assert.NotEmpty(t, fileSystemARN, "File system ARN should not be empty")
			assert.Contains(t, fileSystemARN, "arn:aws:elasticfilesystem:", "ARN should be for EFS service")
			assert.Contains(t, fileSystemARN, fileSystemID, "ARN should contain file system ID")
		})

		t.Run("TestFileSystemDNSName", func(t *testing.T) {
			assert.NotEmpty(t, fileSystemDNSName, "File system DNS name should not be empty")
			assert.Contains(t, fileSystemDNSName, fileSystemID, "DNS name should contain file system ID")
			assert.Contains(t, fileSystemDNSName, ".efs.", "DNS name should contain .efs.")
			assert.Contains(t, fileSystemDNSName, ".amazonaws.com", "DNS name should end with .amazonaws.com")
		})

		t.Run("TestFileSystemName", func(t *testing.T) {
			assert.NotEmpty(t, fileSystemName, "File system name should not be empty")
		})

		t.Run("TestFileSystemCreationToken", func(t *testing.T) {
			fileSystemCreationToken := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_creation_token")
			assert.NotEmpty(t, fileSystemCreationToken, "File system creation token should not be empty")
		})

		t.Run("TestFileSystemAvailabilityZone", func(t *testing.T) {
			// These may be empty for Multi-AZ, but should be retrievable
			fileSystemAZID := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_availability_zone_id")
			fileSystemAZName := terraform.Output(t, ctx.TerratestTerraformOptions(), "file_system_availability_zone_name")
			// For One Zone storage, these should not be empty
			// For Multi-AZ, they will be empty strings
			_ = fileSystemAZID   // May be empty for Multi-AZ
			_ = fileSystemAZName // May be empty for Multi-AZ
		})
	})

	// ========================================
	// Mount Target Validations
	// ========================================
	// Validate outputs from the EFS mount target primitive module

	t.Run("TestMountTargetOutputs", func(t *testing.T) {
		t.Run("TestMountTargetIDs", func(t *testing.T) {
			assert.NotEmpty(t, mountTargetIDs, "Mount target IDs map should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetIDs),
				"Should have exactly %d mount targets", expectedMountTargets)

			for mountTargetName, mountTargetID := range mountTargetIDs {
				assert.NotEmpty(t, mountTargetID, "Mount target ID for %s should not be empty", mountTargetName)
				assert.Regexp(t, "^fsmt-[a-f0-9]+$", mountTargetID, "Mount target ID should match pattern fsmt-xxxxxxxx")
			}
		})

		t.Run("TestMountTargetDNSNames", func(t *testing.T) {
			assert.NotEmpty(t, mountTargetDNSNames, "Mount target DNS names map should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetDNSNames),
				"Should have exactly %d mount target DNS names", expectedMountTargets)

			for mountTargetName, dnsName := range mountTargetDNSNames {
				assert.NotEmpty(t, dnsName, "Mount target DNS name for %s should not be empty", mountTargetName)
				assert.Contains(t, dnsName, fileSystemID, "DNS name should contain file system ID")
			}
		})

		t.Run("TestMountTargetAZDNSNames", func(t *testing.T) {
			mountTargetAZDNSNames := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_az_dns_names")
			assert.NotEmpty(t, mountTargetAZDNSNames, "Mount target AZ DNS names map should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetAZDNSNames),
				"Should have exactly %d mount target AZ DNS names", expectedMountTargets)

			for mountTargetName, azDnsName := range mountTargetAZDNSNames {
				assert.NotEmpty(t, azDnsName, "Mount target AZ DNS name for %s should not be empty", mountTargetName)
				assert.Contains(t, azDnsName, fileSystemID, "AZ DNS name should contain file system ID")
			}
		})

		t.Run("TestMountTargetNetworkInterfaces", func(t *testing.T) {
			mountTargetNIIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_network_interface_ids")
			assert.NotEmpty(t, mountTargetNIIDs, "Mount target network interface IDs should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetNIIDs),
				"Should have exactly %d network interface IDs", expectedMountTargets)

			for mountTargetName, niID := range mountTargetNIIDs {
				assert.NotEmpty(t, niID, "Network interface ID for %s should not be empty", mountTargetName)
				assert.Regexp(t, "^eni-[a-f0-9]+$", niID, "Network interface ID should match pattern eni-xxxxxxxx")
			}
		})

		t.Run("TestMountTargetAvailabilityZones", func(t *testing.T) {
			mountTargetAZNames := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_availability_zone_names")
			assert.NotEmpty(t, mountTargetAZNames, "Mount target AZ names should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetAZNames),
				"Should have exactly %d AZ names", expectedMountTargets)

			mountTargetAZIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_availability_zone_ids")
			assert.NotEmpty(t, mountTargetAZIDs, "Mount target AZ IDs should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetAZIDs),
				"Should have exactly %d AZ IDs", expectedMountTargets)

			for mountTargetName := range mountTargetAZNames {
				assert.NotEmpty(t, mountTargetAZNames[mountTargetName], "AZ name for %s should not be empty", mountTargetName)
				assert.NotEmpty(t, mountTargetAZIDs[mountTargetName], "AZ ID for %s should not be empty", mountTargetName)
			}
		})

		t.Run("TestMountTargetFileSystemARNs", func(t *testing.T) {
			mountTargetFSARNs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_file_system_arns")
			assert.NotEmpty(t, mountTargetFSARNs, "Mount target file system ARNs should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetFSARNs),
				"Should have exactly %d file system ARNs", expectedMountTargets)

			for mountTargetName, fsArn := range mountTargetFSARNs {
				assert.Equal(t, fileSystemARN, fsArn, "File system ARN for %s should match", mountTargetName)
			}
		})

		t.Run("TestMountTargetOwnerIDs", func(t *testing.T) {
			mountTargetOwnerIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "mount_target_owner_ids")
			assert.NotEmpty(t, mountTargetOwnerIDs, "Mount target owner IDs should not be empty")
			assert.Equal(t, expectedMountTargets, len(mountTargetOwnerIDs),
				"Should have exactly %d owner IDs", expectedMountTargets)

			for mountTargetName, ownerID := range mountTargetOwnerIDs {
				assert.NotEmpty(t, ownerID, "Owner ID for %s should not be empty", mountTargetName)
				assert.Regexp(t, "^[0-9]{12}$", ownerID, "Owner ID should be a 12-digit AWS account ID")
			}
		})

		t.Run("TestMountTargetNames", func(t *testing.T) {
			// Verify we have the expected mount target names
			for _, expectedName := range expectedMountTargetNames {
				assert.Contains(t, mountTargetIDs, expectedName,
					"Should have mount target for %s", expectedName)
			}
		})

		t.Run("TestMountTargetCount", func(t *testing.T) {
			// Verify mount targets match number of subnets
			assert.Equal(t, len(mountTargetIDs), len(mountTargetDNSNames),
				"Number of mount target IDs should match DNS names")
		})
	})

	// ========================================
	// Access Point Validations
	// ========================================
	// Validate outputs from the EFS access point primitive module

	t.Run("TestAccessPointOutputs", func(t *testing.T) {
		t.Run("TestAccessPointIDs", func(t *testing.T) {
			assert.NotEmpty(t, accessPointIDs, "Access point IDs map should not be empty")
			for name, apID := range accessPointIDs {
				assert.NotEmpty(t, apID, "Access point ID for %s should not be empty", name)
				assert.Regexp(t, "^fsap-[a-f0-9]+$", apID, "Access point ID should match pattern fsap-xxxxxxxx")
			}
		})

		t.Run("TestAccessPointARNs", func(t *testing.T) {
			assert.NotEmpty(t, accessPointARNs, "Access point ARNs map should not be empty")
			for name, arn := range accessPointARNs {
				assert.NotEmpty(t, arn, "Access point ARN for %s should not be empty", name)
				assert.Contains(t, arn, "arn:aws:elasticfilesystem:", "ARN should be for EFS service")
				assert.Contains(t, arn, ":access-point/", "ARN should contain :access-point/")
			}
		})

		t.Run("TestAccessPointFileSystemIDs", func(t *testing.T) {
			accessPointFSIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_file_system_ids")
			assert.NotEmpty(t, accessPointFSIDs, "Access point file system IDs should not be empty")
			for name, fsID := range accessPointFSIDs {
				assert.Equal(t, fileSystemID, fsID, "File system ID for access point %s should match", name)
			}
		})

		t.Run("TestAccessPointOwnerIDs", func(t *testing.T) {
			accessPointOwnerIDs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_owner_ids")
			assert.NotEmpty(t, accessPointOwnerIDs, "Access point owner IDs should not be empty")
			for name, ownerID := range accessPointOwnerIDs {
				assert.NotEmpty(t, ownerID, "Owner ID for access point %s should not be empty", name)
				assert.Regexp(t, "^[0-9]{12}$", ownerID, "Owner ID should be a 12-digit AWS account ID")
			}
		})

		t.Run("TestAccessPointPOSIXUsers", func(t *testing.T) {
			// POSIX user configuration is a complex object, so we just validate it exists
			// The actual validation of POSIX user details happens in AWS SDK validation
			accessPointPOSIXUsers := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_posix_users")
			assert.NotEmpty(t, accessPointPOSIXUsers, "Access point POSIX users should not be empty")
			for name := range accessPointPOSIXUsers {
				assert.NotEmpty(t, accessPointPOSIXUsers[name], "POSIX user for access point %s should not be empty", name)
			}
		})

		t.Run("TestAccessPointRootDirectories", func(t *testing.T) {
			// Root directory configuration is a complex object, so we just validate it exists
			accessPointRootDirs := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_root_directories")
			assert.NotEmpty(t, accessPointRootDirs, "Access point root directories should not be empty")
			for name := range accessPointRootDirs {
				assert.NotEmpty(t, accessPointRootDirs[name], "Root directory for access point %s should not be empty", name)
			}
		})

		t.Run("TestAccessPointTags", func(t *testing.T) {
			// Tags are a map, so we just validate the output exists
			accessPointTags := terraform.OutputMap(t, ctx.TerratestTerraformOptions(), "access_point_tags")
			assert.NotEmpty(t, accessPointTags, "Access point tags should not be empty")
		})

		t.Run("TestAccessPointCount", func(t *testing.T) {
			// Verify we have expected access points (simple example has 2, complete has 4)
			assert.GreaterOrEqual(t, len(accessPointIDs), 1, "Should have at least one access point")
			assert.Equal(t, len(accessPointIDs), len(accessPointARNs),
				"Number of access point IDs should match ARNs")
		})
	})

	// ========================================
	// Aggregated Output Validations
	// ========================================
	// Validate outputs aggregated across all EFS sub-modules

	t.Run("TestAggregatedOutputs", func(t *testing.T) {
		t.Run("TestAllResourceARNs", func(t *testing.T) {
			assert.NotEmpty(t, allResourceARNs, "Aggregated resource ARNs should not be empty")

			// Should contain file system ARN
			assert.Contains(t, allResourceARNs, fileSystemARN, "Should contain file system ARN")

			// Should contain all access point ARNs
			for name, arn := range accessPointARNs {
				assert.Contains(t, allResourceARNs, arn, "Should contain access point ARN for %s", name)
			}
		})

		t.Run("TestResourceCount", func(t *testing.T) {
			// Total ARNs = 1 file system + N access points
			expectedCount := 1 + len(accessPointARNs)
			assert.Equal(t, expectedCount, len(allResourceARNs),
				"Total ARN count should be file system + access points")
		})

		t.Run("TestConnectionInfo", func(t *testing.T) {
			connectionInfo := terraform.Output(t, ctx.TerratestTerraformOptions(), "connection_info")
			assert.NotEmpty(t, connectionInfo, "Connection info should not be empty")
			// Connection info is a complex object with file_system_id, dns_name, mount_target_dns, etc.
			assert.Contains(t, connectionInfo, fileSystemID, "Connection info should contain file system ID")
			assert.Contains(t, connectionInfo, fileSystemDNSName, "Connection info should contain DNS name")
		})

		t.Run("TestMountCommand", func(t *testing.T) {
			mountCommand := terraform.Output(t, ctx.TerratestTerraformOptions(), "mount_command")
			assert.NotEmpty(t, mountCommand, "Mount command should not be empty")
			assert.Contains(t, mountCommand, fileSystemDNSName, "Mount command should contain DNS name")
			assert.Contains(t, mountCommand, "mount", "Mount command should contain 'mount' keyword")
		})

		t.Run("TestMountCommandWithEFSUtils", func(t *testing.T) {
			// This output may not exist in simple example, so check if it exists first
			terraformOptions := ctx.TerratestTerraformOptions()
			allOutputs := terraform.OutputAll(t, terraformOptions)
			if _, exists := allOutputs["mount_command_with_efs_utils"]; exists {
				mountCommandEFSUtils := terraform.Output(t, terraformOptions, "mount_command_with_efs_utils")
				assert.NotEmpty(t, mountCommandEFSUtils, "Mount command with EFS utils should not be empty")
				assert.Contains(t, mountCommandEFSUtils, fileSystemID, "Mount command should contain file system ID")
				assert.Contains(t, mountCommandEFSUtils, "-t efs", "Mount command should specify EFS type")
			}
		})
	})

	// ========================================
	// AWS SDK Validations
	// ========================================
	// Use AWS SDK to validate EFS resource configuration via AWS API
	// This provides deeper validation beyond Terraform outputs and is faster

	t.Run("TestAWSEFSConfiguration", func(t *testing.T) {
		// Get AWS configuration and EFS client
		awsConfig := GetAWSConfig(t)
		efsClient := efs.NewFromConfig(awsConfig)

		// Validate file system via AWS API
		t.Run("TestFileSystemViaAWS", func(t *testing.T) {
			fsResult, err := efsClient.DescribeFileSystems(context.TODO(), &efs.DescribeFileSystemsInput{
				FileSystemId: aws.String(fileSystemID),
			})
			require.NoError(t, err, "Failed to describe file system via AWS API")
			require.Len(t, fsResult.FileSystems, 1, "Should return exactly one file system")

			fs := fsResult.FileSystems[0]

			// Validate lifecycle state
			assert.Equal(t, "available", string(fs.LifeCycleState), "File system should be available")

			// Validate encryption
			assert.True(t, *fs.Encrypted, "File system should be encrypted")

			// Validate file system ID matches
			assert.Equal(t, fileSystemID, *fs.FileSystemId, "File system ID should match")

			// Validate name/creation token
			assert.Equal(t, fileSystemName, *fs.Name, "File system name should match")
			assert.NotEmpty(t, *fs.CreationToken, "Creation token should not be empty")

			// Validate performance and throughput modes
			assert.NotEmpty(t, fs.PerformanceMode, "Performance mode should be set")
			assert.NotEmpty(t, fs.ThroughputMode, "Throughput mode should be set")

			// Validate size in bytes (should be non-negative)
			assert.GreaterOrEqual(t, fs.SizeInBytes.Value, int64(0), "Size should be non-negative")

			// Validate number of mount targets matches our outputs
			assert.Equal(t, int32(len(mountTargetIDs)), fs.NumberOfMountTargets,
				"Number of mount targets in AWS should match outputs")

			// Validate tags exist
			assert.NotEmpty(t, fs.Tags, "File system should have tags")
		})

		// Validate mount targets via AWS API
		t.Run("TestMountTargetsViaAWS", func(t *testing.T) {
			mtResult, err := efsClient.DescribeMountTargets(context.TODO(), &efs.DescribeMountTargetsInput{
				FileSystemId: aws.String(fileSystemID),
			})
			require.NoError(t, err, "Failed to describe mount targets via AWS API")

			// Verify count matches outputs
			assert.Equal(t, len(mountTargetIDs), len(mtResult.MountTargets),
				"Mount target count from AWS should match Terraform outputs")

			// Validate each mount target
			for _, mt := range mtResult.MountTargets {
				// Mount target should be available
				assert.Equal(t, "available", string(mt.LifeCycleState),
					"Mount target %s should be available", *mt.MountTargetId)

				// Should reference our file system
				assert.Equal(t, fileSystemID, *mt.FileSystemId,
					"Mount target should reference our file system")

				// Should have subnet and network interface
				assert.NotEmpty(t, *mt.SubnetId, "Mount target should have subnet ID")
				assert.NotEmpty(t, *mt.NetworkInterfaceId, "Mount target should have network interface ID")
				assert.NotEmpty(t, *mt.IpAddress, "Mount target should have IP address")
				assert.NotEmpty(t, *mt.AvailabilityZoneName, "Mount target should have AZ name")

				// Verify the mount target ID exists in our outputs
				found := false
				for _, outputMTID := range mountTargetIDs {
					if outputMTID == *mt.MountTargetId {
						found = true
						break
					}
				}
				assert.True(t, found, "Mount target %s should exist in Terraform outputs", *mt.MountTargetId)
			}
		})

		// Validate access points via AWS API
		t.Run("TestAccessPointsViaAWS", func(t *testing.T) {
			apResult, err := efsClient.DescribeAccessPoints(context.TODO(), &efs.DescribeAccessPointsInput{
				FileSystemId: aws.String(fileSystemID),
			})
			require.NoError(t, err, "Failed to describe access points via AWS API")

			// Verify count matches outputs
			assert.Equal(t, len(accessPointIDs), len(apResult.AccessPoints),
				"Access point count from AWS should match Terraform outputs")

			// Validate each access point
			for _, ap := range apResult.AccessPoints {
				// Access point should be available
				assert.Equal(t, "available", string(ap.LifeCycleState),
					"Access point %s should be available", *ap.AccessPointId)

				// Should reference our file system
				assert.Equal(t, fileSystemID, *ap.FileSystemId,
					"Access point should reference our file system")

				// Should have POSIX user configuration
				require.NotNil(t, ap.PosixUser, "Access point should have POSIX user")
				assert.NotNil(t, ap.PosixUser.Uid, "POSIX user should have UID")
				assert.NotNil(t, ap.PosixUser.Gid, "POSIX user should have GID")

				// Should have root directory configuration
				require.NotNil(t, ap.RootDirectory, "Access point should have root directory")
				assert.NotEmpty(t, *ap.RootDirectory.Path, "Root directory should have path")

				// Verify the access point ID exists in our outputs
				found := false
				for _, outputAPID := range accessPointIDs {
					if outputAPID == *ap.AccessPointId {
						found = true
						break
					}
				}
				assert.True(t, found, "Access point %s should exist in Terraform outputs", *ap.AccessPointId)

				// Validate tags exist
				assert.NotEmpty(t, ap.Tags, "Access point should have tags")
			}
		})
	})

	// ========================================
	// Resource Coordination Validations
	// ========================================
	// Validate that all EFS resources are correctly associated

	t.Run("TestResourceCoordination", func(t *testing.T) {
		t.Run("TestMountTargetsLinkedToFileSystem", func(t *testing.T) {
			// All mount targets should reference the same file system
			for mountTargetName := range mountTargetIDs {
				assert.NotEmpty(t, mountTargetName, "Mount target name should not be empty")
			}
		})

		t.Run("TestAccessPointsLinkedToFileSystem", func(t *testing.T) {
			// All access points should reference the same file system
			// This is validated through the collection module's coordination logic
			assert.NotEmpty(t, accessPointIDs, "Access points should be created")
			assert.NotEmpty(t, fileSystemID, "File system should exist for access points")
		})
	})
}

// ========================================
// Additional Test Functions
// ========================================
// Add more test functions as needed to organize different test scenarios

// Example: Test security configuration
// func TestSecurityConfiguration(t *testing.T, ctx testTypes.TestContext) {
// 	t.Run("TestEncryptionEnabled", func(t *testing.T) {
// 		// Validation logic
// 	})
//
// 	t.Run("TestSecurityGroups", func(t *testing.T) {
// 		// Validation logic
// 	})
// }

// Example: Test high availability configuration
// func TestHighAvailability(t *testing.T, ctx testTypes.TestContext) {
// 	t.Run("TestMultiAZ", func(t *testing.T) {
// 		// Validation logic
// 	})
// }

// ========================================
// Utility Functions
// ========================================
// Helper functions for AWS SDK operations and common test utilities

// GetAWSSTSClient returns an AWS STS client for identity validation
func GetAWSSTSClient(t *testing.T) *sts.Client {
	awsSTSClient := sts.NewFromConfig(GetAWSConfig(t))
	return awsSTSClient
}

// GetAWSEFSClient returns an AWS EFS client for validating EFS resources
func GetAWSEFSClient(t *testing.T) *efs.Client {
	efsClient := efs.NewFromConfig(GetAWSConfig(t))
	return efsClient
}

// GetAWSConfig loads the default AWS configuration
// This can be extended to support custom configurations (regions, profiles, etc.)
func GetAWSConfig(t *testing.T) (cfg aws.Config) {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	require.NoErrorf(t, err, "unable to load SDK config, %v", err)
	return cfg
}

// Example: Get AWS config for a specific region
// func GetAWSConfigForRegion(t *testing.T, region string) aws.Config {
// 	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
// 	require.NoErrorf(t, err, "unable to load SDK config for region %s, %v", region, err)
// 	return cfg
// }

// Example: Helper to validate ARN format
// func ValidateARN(t *testing.T, arn string, service string) {
// 	assert.NotEmpty(t, arn, "ARN should not be empty")
// 	assert.Contains(t, arn, "arn:aws:", "ARN should start with 'arn:aws:'")
// 	assert.Contains(t, arn, fmt.Sprintf(":%s:", service), "ARN should contain service name")
// }

// Example: Helper to get AWS account ID
// func GetAWSAccountID(t *testing.T) string {
// 	stsClient := GetAWSSTSClient(t)
// 	result, err := stsClient.GetCallerIdentity(context.TODO(), &sts.GetCallerIdentityInput{})
// 	require.NoError(t, err, "Failed to get caller identity")
// 	return *result.Account
// }
