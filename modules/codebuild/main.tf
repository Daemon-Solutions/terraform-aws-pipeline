// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.main
// SPDX-License-Identifier: MIT-0

locals {
  build_spec_path = var.build_spec_override != "" ? var.build_spec_override : "${path.module}/buildspecs/${var.build_spec}"
}

resource "aws_codebuild_project" "this" {
  name          = var.codebuild_name
  build_timeout = var.build_timeout
  service_role  = var.codebuild_role

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = var.image
    type         = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.log_group
      stream_name = var.codebuild_name
    }
  }

  source {
    type                = "CODEPIPELINE"
    buildspec           = file("${local.build_spec_path}")
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
  }
}
