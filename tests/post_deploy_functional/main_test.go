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

package test

import (
	"testing"

	"github.com/launchbynttdata/lcaf-component-terratest/lib"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/launchbynttdata/tf-aws-module_collection-efs/tests/testimpl"
)

const (
	testConfigsExamplesFolderDefault = "../../examples/complete"
	infraTFVarFileNameDefault        = "test.tfvars"
)

// TestEFSCollectionModule tests the complete example with actual resource deployment
// This test will:
// 1. Deploy with all 3 subnets enabled (default)
// 2. Update to remove subnet B (indices [0, 2])
// 3. Update to remove subnet A and restore B (indices [1, 2])
// 4. Destroy all resources
func TestEFSCollectionModule(t *testing.T) {

	ctx := types.CreateTestContextBuilder().
		SetTestConfig(&testimpl.ThisTFModuleConfig{}).
		SetTestConfigFolderName(testConfigsExamplesFolderDefault).
		SetTestConfigFileName(infraTFVarFileNameDefault).
		Build()

	lib.RunSetupTestTeardown(t, *ctx, testimpl.TestComposableEFSCollectionComplete)
}
