// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  validation_stages = merge({
    validate = "hashicorp/terraform:${var.terraform_version}"
    fmt      = "hashicorp/terraform:${var.terraform_version}"
    },
    var.validation_sast_settings.enabled ? {
      sast = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    } : {},
    var.validation_lint_settings.enabled ? {
      lint = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    } : {}
  )


  conditional_validation_stages = merge(local.validation_stages, {
    tags = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  })

  env_var = merge(var.env_vars, {
    CHECKOV_SKIPS         = join(",", "${var.checkov_skip}")
    CHECKOV_VERSION       = var.checkov_version
    SAST_REPORT_ARN       = aws_codebuild_report_group.sast.arn
    LINT_REPORT_ARN       = aws_codebuild_report_group.lint.arn
    TF_VERSION            = var.terraform_version
    TFLINT_VERSION        = var.tflint_version
    SOURCE_DIR            = var.source_dir
    GITHUB_KEY            = var.github_key
    ASSUME_ROLE_ARN       = var.assume_role_arn
    CONTINUE_ON_LINT_FAIL = var.validation_lint_settings.continue_on_failure
    CONTINUE_ON_SAST_FAIL = var.validation_sast_settings.continue_on_failure
  })

  conditional_env_var = merge(local.env_var, {
    TAGS           = var.tags
    TAGNAG_VERSION = var.tagnag_version
  })

  codebuild_projects = merge({
    for stage, _ in var.tags == "" ? local.validation_stages : local.conditional_validation_stages :
    module.validation[stage].codebuild_project.name => module.validation[stage].codebuild_project.arn
    },
    {
      for repo in local.terraform_repos :
      module.plan[repo.repo_id].codebuild_project.name => module.plan[repo.repo_id].codebuild_project.arn
    },
    {
      for repo in local.terraform_repos :
      module.apply[repo.repo_id].codebuild_project.name => module.apply[repo.repo_id].codebuild_project.arn
    }
  )


  terraform_repos = length(var.terraform_repos) > 0 ? [
    for r in var.terraform_repos : {
      path     = join("/", [trim(var.source_dir, "/"), trim(r.path, "/")])
      repo_id  = "${var.pipeline_name}-${r.repo_id}"
      env_vars = r.env_vars
    }] : [
    {
      path     = var.source_dir
      repo_id  = var.pipeline_name
      env_vars = var.env_vars
    }
  ]
}
