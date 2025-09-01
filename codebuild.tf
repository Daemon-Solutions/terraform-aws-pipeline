// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

module "check_directory" {
  source         = "./modules/codebuild"
  codebuild_name = "${var.pipeline_name}-check-dir"
  codebuild_role = aws_iam_role.codebuild_execution.arn
  environment_variables = {
    SOURCE_DIR = var.source_dir
  }
  build_timeout = var.build_timeout
  build_spec    = "check_dir.yml"
  log_group     = aws_cloudwatch_log_group.this.name
  image         = "aws/codebuild/standard:5.0"
}

module "validation" {
  for_each              = var.tags == "" ? local.validation_stages : local.conditional_validation_stages
  source                = "./modules/codebuild"
  codebuild_name        = "${var.pipeline_name}-${each.key}"
  codebuild_role        = aws_iam_role.codebuild_validate.arn
  environment_variables = var.tags == "" ? local.env_var : local.conditional_env_var
  build_timeout         = var.build_timeout
  build_spec            = "${each.key}.yml"
  log_group             = aws_cloudwatch_log_group.this.name
  image                 = each.value
}

module "plan" {
  for_each       = { for r in local.terraform_repos : r.repo_id => r }
  source         = "./modules/codebuild"
  codebuild_name = "${each.key}-plan"
  codebuild_role = aws_iam_role.codebuild_execution.arn
  environment_variables = merge(local.env_var, each.value.env_vars, {
    SOURCE_DIR = each.value.path
  })
  build_timeout       = var.build_timeout
  build_spec          = "plan.yml"
  build_spec_override = var.plan_spec
  log_group           = aws_cloudwatch_log_group.this.name
  image               = "hashicorp/terraform:${var.terraform_version}"
}

module "apply" {
  for_each       = { for r in local.terraform_repos : r.repo_id => r }
  source         = "./modules/codebuild"
  codebuild_name = "${each.key}-apply"
  codebuild_role = aws_iam_role.codebuild_execution.arn
  environment_variables = merge(local.env_var, each.value.env_vars, {
    SOURCE_DIR = each.value.path
  })
  build_timeout       = var.build_timeout
  build_spec          = "apply.yml"
  build_spec_override = var.apply_spec
  log_group           = aws_cloudwatch_log_group.this.name
  image               = "hashicorp/terraform:${var.terraform_version}"
}


resource "aws_iam_role" "codebuild_validate" {
  name               = "${var.pipeline_name}-codebuild-validate"
  assume_role_policy = data.aws_iam_policy_document.codebuild_validate_assume.json
}

resource "aws_iam_role" "codebuild_execution" {
  name               = "${var.pipeline_name}-codebuild-execution"
  assume_role_policy = data.aws_iam_policy_document.codebuild_execution_assume.json
}

data "aws_iam_policy_document" "codebuild_validate_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
      ]
    }
  }
}

data "aws_iam_policy_document" "codebuild_execution_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${var.pipeline_name}-*"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_validate" {
  role       = aws_iam_role.codebuild_validate.name
  policy_arn = aws_iam_policy.codebuild_validate.arn
}

resource "aws_iam_role_policy_attachment" "codebuild_execution" {
  role       = aws_iam_role.codebuild_execution.name
  policy_arn = var.codebuild_policy == null ? "arn:aws:iam::aws:policy/AdministratorAccess" : var.codebuild_policy
}

resource "aws_iam_policy" "codebuild_validate" {
  name   = "${var.pipeline_name}-codebuild-validate"
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy_attachment" "codebuild_validate_source_access" {
  role       = aws_iam_role.codebuild_validate.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases"
    ]

    resources = [
      aws_codebuild_report_group.sast.arn,
      aws_codebuild_report_group.lint.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.additional_codebuild_statements

    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}
resource "aws_codebuild_report_group" "sast" {
  name           = "sast-report-${var.pipeline_name}"
  type           = "TEST"
  delete_reports = true

  export_config {
    type = "S3"

    s3_destination {
      bucket              = aws_s3_bucket.this.id
      encryption_disabled = false
      encryption_key      = var.kms_key == null ? data.aws_kms_key.s3.arn : var.kms_key
      packaging           = "NONE"
      path                = "/sast"
    }
  }
}

resource "aws_codebuild_report_group" "lint" {
  name           = "lint-report-${var.pipeline_name}"
  type           = "TEST"
  delete_reports = true

  export_config {
    type = "S3"

    s3_destination {
      bucket              = aws_s3_bucket.this.id
      encryption_disabled = false
      encryption_key      = var.kms_key == null ? data.aws_kms_key.s3.arn : var.kms_key
      packaging           = "NONE"
      path                = "/lint"
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${var.pipeline_name}"
  retention_in_days = var.log_retention
  kms_key_id        = var.kms_key
}
