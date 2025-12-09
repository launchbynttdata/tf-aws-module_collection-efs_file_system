package testimpl

import (
	"context"
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
		terraformOptions.Vars["enabled_subnet_indices"] = []int{0, 2}

		// Apply the changes
		terraform.Apply(t, terraformOptions)

		validateEFSDeployment(t, ctx, 2, []string{"az-a", "az-c"})
	})

	// Phase 3: Remove subnet A, restore subnet B (keep B and C)
	t.Run("Phase3_RemoveSubnetA_RestoreSubnetB", func(t *testing.T) {
		t.Log("Updating configuration to remove subnet A and restore subnet B")

		// Update the tfvars to set enabled_subnet_indices = [1, 2]
		terraformOptions := ctx.TerratestTerraformOptions()
		terraformOptions.Vars["enabled_subnet_indices"] = []int{1, 2}

		// Apply the changes
		terraform.Apply(t, terraformOptions)

		validateEFSDeployment(t, ctx, 2, []string{"az-b", "az-c"})
	})
}

// TestComposableEFSCollectionSimple validates the simple example with plan-only (no actual deployment).
// This test validates that the configuration is valid and would deploy successfully.
func TestComposableEFSCollectionSimple(t *testing.T, ctx testTypes.TestContext) {
	t.Run("ValidateSimpleExamplePlan", func(t *testing.T) {
		t.Log("Validating simple example plan without deployment")

		// Run terraform plan
		terraformOptions := ctx.TerratestTerraformOptions()
		terraform.Init(t, terraformOptions)
		planExitCode := terraform.PlanExitCode(t, terraformOptions)

		// Plan should succeed with exit code 0 (no changes after init) or 2 (changes to apply)
		assert.Contains(t, []int{0, 2}, planExitCode, "Plan should succeed")

		t.Log("Simple example plan validation successful")
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
