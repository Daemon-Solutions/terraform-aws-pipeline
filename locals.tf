// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  all_validation_stages = {
    validate = "hashicorp/terraform:${var.terraform_version}"
    fmt      = "hashicorp/terraform:${var.terraform_version}"
    lint     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    sast     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  }


  validation_stage_flags = merge({
    validate = true
    fmt      = true
    lint     = false
    sast     = false
  }, var.validation_stage_flags)

  validation_stages = {
    for stage, enabled in local.validation_stage_flags :
    stage => local.all_validation_stages[stage]
    if enabled && contains(keys(local.all_validation_stages), stage)
  }



  conditional_validation_stages = merge(local.validation_stages, {
    tags = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  })

  env_var = merge(var.env_vars, {
    CHECKOV_SKIPS   = join(",", "${var.checkov_skip}")
    CHECKOV_VERSION = var.checkov_version
    SAST_REPORT_ARN = aws_codebuild_report_group.sast.arn
    TF_VERSION      = var.terraform_version
    TFLINT_VERSION  = var.tflint_version
    SOURCE_DIR      = var.source_dir
    GITHUB_KEY      = var.github_key
    ASSUME_ROLE_ARN = var.assume_role_arn
  })

  conditional_env_var = merge(local.env_var, {
    TAGS           = var.tags
    TAGNAG_VERSION = var.tagnag_version
  })
}
