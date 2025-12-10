# ========================================
# Resource Naming Configuration
# ========================================

logical_product_family  = "launch"
logical_product_service = "efs"
environment             = "prod"
instance_env            = 0
instance_resource       = 0
aws_region              = "us-west-2"

# ========================================
# VPC and Networking
# ========================================

vpc_cidr_block = "10.1.0.0/16"

# Define three subnets across different AZs using letter suffixes
# The full AZ name will be constructed as: {region}{az_letter}
# Example: us-west-2 + a = us-west-2a
subnet_configs = [
  {
    cidr_block = "10.1.1.0/24"
    az_letter  = "a"
  },
  {
    cidr_block = "10.1.2.0/24"
    az_letter  = "b"
  },
  {
    cidr_block = "10.1.3.0/24"
    az_letter  = "c"
  }
]

# Test scenarios for mount target creation:
# 1. All subnets enabled (default): enabled_subnet_indices = null or [0, 1, 2]
# 2. Remove middle subnet: enabled_subnet_indices = [0, 2]
# 3. Only first and second: enabled_subnet_indices = [0, 1]
# 4. Single subnet: enabled_subnet_indices = [1]
# Start with all subnets enabled
enabled_subnet_indices = null

# One Zone storage configuration (set to true to reduce costs)
use_one_zone_storage       = false
one_zone_availability_zone = null # Will use first available AZ if use_one_zone_storage = true

# ========================================
# KMS Configuration
# ========================================

kms_deletion_window_days = 10
enable_kms_key_rotation  = true

# ========================================
# EFS File System Configuration
# ========================================

custom_file_system_name = null # Will use resource_names module output

# Performance settings
performance_mode = "generalPurpose" # or "maxIO" for high parallelism
throughput_mode  = "elastic"        # "bursting", "provisioned", or "elastic"

# Only used when throughput_mode = "provisioned"
provisioned_throughput_in_mibps = 256

# Lifecycle management - optimize costs with tiered storage
lifecycle_transition_to_ia      = "AFTER_7_DAYS"   # Move to IA after 7 days
lifecycle_transition_to_primary = "AFTER_1_ACCESS" # Move back to primary on access
lifecycle_transition_to_archive = "AFTER_90_DAYS"  # Move to Archive after 90 days

# Replication protection (for multi-region replication scenarios)
enable_replication_protection    = false
replication_overwrite_protection = "ENABLED" # "ENABLED", "DISABLED", or "REPLICATING"

# ========================================
# Mount Target Configuration
# ========================================

mount_target_create_timeout = "30m"
mount_target_delete_timeout = "15m"

# ========================================
# Access Point Configuration
# ========================================

access_point_configurations = {
  web_app = {
    posix_user = {
      uid            = 1000
      gid            = 1000
      secondary_gids = [1001, 1002]
    }
    root_directory_path = "/web"
    root_directory_creation_info = {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
    tags = {
      Application = "WebApp"
      Team        = "Frontend"
    }
  }

  api_backend = {
    posix_user = {
      uid            = 2000
      gid            = 2000
      secondary_gids = [2001]
    }
    root_directory_path = "/api"
    root_directory_creation_info = {
      owner_uid   = 2000
      owner_gid   = 2000
      permissions = "0750"
    }
    tags = {
      Application = "API"
      Team        = "Backend"
    }
  }

  batch_jobs = {
    posix_user = {
      uid = 3000
      gid = 3000
    }
    root_directory_path = "/batch"
    root_directory_creation_info = {
      owner_uid   = 3000
      owner_gid   = 3000
      permissions = "0770"
    }
    tags = {
      Application = "BatchProcessing"
      Team        = "DataEngineering"
    }
  }

  shared_data = {
    posix_user = {
      uid            = 4000
      gid            = 4000
      secondary_gids = [4001, 4002, 4003]
    }
    root_directory_path = "/shared"
    root_directory_creation_info = {
      owner_uid   = 4000
      owner_gid   = 4000
      permissions = "0775"
    }
    tags = {
      Application = "SharedStorage"
      Team        = "Operations"
    }
  }
}

# ========================================
# Monitoring Configuration
# ========================================

burst_credit_alarm_threshold       = 1000000000000 # 1 TiB
client_connections_alarm_threshold = 1000

# ========================================
# Common Tags
# ========================================

tags = {
  CostCenter = "engineering"
  Compliance = "required"
  Backup     = "daily"
}
