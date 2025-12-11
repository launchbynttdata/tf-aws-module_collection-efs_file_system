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

# Simple Example - EFS Collection Module Usage
# Creates VPC infrastructure and deploys a complete EFS solution

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC for the example
resource "aws_vpc" "example" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.resource_name}-vpc"
    Environment = var.environment
  }
}

# Single subnet for minimal example
resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.resource_name}-subnet"
  }
}

# Security group for EFS mount targets
# Must allow NFS traffic (port 2049) from EC2 instances
resource "aws_security_group" "efs_mount_target" {
  name        = "${var.resource_name}-efs-mt-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.example.id

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resource_name}-efs-mt-sg"
  }
}

# EFS Collection Module Call
# Creates file system, mount targets, and access points
module "efs" {
  source = "../../"

  name        = var.resource_name
  environment = var.environment

  # File system configuration
  encrypted        = var.encrypted
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode

  # Lifecycle policy
  lifecycle_policy = var.lifecycle_policy

  # Mount target configuration
  create_mount_targets = true
  # Single mount target for simple example
  mount_target_subnet_ids = {
    "primary" = aws_subnet.example.id
  }
  mount_target_security_group_ids = [aws_security_group.efs_mount_target.id]

  # Access points
  access_point_configurations = var.access_point_configurations

  tags = merge(
    var.tags,
    {
      Example = "simple"
    }
  )
}
