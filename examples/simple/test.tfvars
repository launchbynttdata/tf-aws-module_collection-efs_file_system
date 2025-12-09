region        = "us-west-2"
resource_name = "efs-test"
environment   = "dev"

# VPC Configuration
vpc_cidr_block = "10.0.0.0/16"
subnet_count   = 2

# EFS Configuration
encrypted        = true
performance_mode = "generalPurpose"
throughput_mode  = "bursting"

lifecycle_policy = {
  transition_to_ia = "AFTER_30_DAYS"
}

# Access Point Configurations
access_point_configurations = {
  app1 = {
    posix_user = {
      uid = 1000
      gid = 1000
    }
    root_directory_path = "/app1"
    root_directory_creation_info = {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }
  app2 = {
    posix_user = {
      uid = 1001
      gid = 1001
    }
    root_directory_path = "/app2"
    root_directory_creation_info = {
      owner_uid   = 1001
      owner_gid   = 1001
      permissions = "750"
    }
  }
}

tags = {
  Terraform   = "true"
  Environment = "dev"
  Purpose     = "testing"
}
