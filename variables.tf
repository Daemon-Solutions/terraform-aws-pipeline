// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "pipeline_name" {
  type = string
}

variable "repo" {
  description = "source repo name"
  type        = string
}

// optional

variable "access_logging_bucket" {
  description = "s3 server access logging bucket arn"
  type        = string
  default     = null
}

variable "artifact_retention" {
  description = "s3 artifact bucket retention, in days"
  type        = number
  default     = 90
}

variable "branch" {
  description = "branch to source"
  type        = string
  default     = "main"
}

variable "build_timeout" {
  description = "CodeBuild project build timeout"
  type        = number
  default     = 10
}

variable "checkov_skip" {
  description = "list of checkov checks to skip"
  type        = list(string)
  default     = [""]
}

variable "checkov_version" {
  type    = string
  default = "3.2.0"
}

variable "codebuild_policy" {
  description = "replaces CodeBuild's AWSAdministratorAccess IAM policy"
  type        = string
  default     = null
}

variable "connection" {
  description = "arn of the CodeConnection"
  type        = string
  default     = null
}

variable "detect_changes" {
  description = "allows third-party servicesm like GitHub to invoke the pipeline"
  type        = bool
  default     = false
}

variable "log_retention" {
  description = "CloudWatch log group retention, in days"
  type        = number
  default     = 90
}

variable "mode" {
  description = "pipeline execution mode"
  type        = string
  default     = "SUPERSEDED"
  validation {
    condition = contains([
      "SUPERSEDED",
      "PARALLEL",
      "QUEUED"
    ], var.mode)
    error_message = "unsupported pipeline mode"
  }
}

variable "kms_key" {
  description = "AWS KMS key ARN"
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to check for"
  type        = string
  default     = ""
}

variable "tagnag_version" {
  type    = string
  default = "0.5.8"
}

variable "terraform_version" {
  type    = string
  default = "1.5.7"
}

variable "tflint_version" {
  type    = string
  default = "0.48.0"
}


variable "plan_spec" {
  description = "plan spec file"
  type        = string
}

variable "apply_spec" {
  description = "apply spec file"
  type        = string
}

variable "env_vars" {
  description = "Extra environment variables to be passed to CodeBuild"
  type        = map(string)
  default     = {}
}

variable "source_dir" {
  description = "CodeBuild source directory"
  type        = string
  default     = "."
}


variable "github_key" {
  description = "GitHub private key to access interal repositories"
  type        = string
  default     = ""
}

variable "assume_role_arn" {
  description = "IAM role ARN to assume for CodeBuild"
  type        = string
}


variable "manual_approve" {
  description = "Determines whether to add a manual approval step before the apply stage."
  type        = bool
  default     = true
}


variable "enable_notifications" {
  description = "Enable notifications for the pipeline"
  type        = bool
  default     = true

}


variable "codebuild_event_ids" {
  type = list(string)
  default = [
    "codebuild-project-build-state-failed",
    "codebuild-project-build-state-succeeded"
  ]
}

variable "codepipeline_event_ids" {
  type = list(string)
  default = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-stage-execution-resumed",
    "codepipeline-pipeline-stage-execution-failed",
    "codepipeline-pipeline-stage-execution-canceled",
    "codepipeline-pipeline-manual-approval-needed",
  ]
}


variable "validation_sast_settings" {
  description = "Settings for sast validation stage. Valid values for on_failure are the same as the codebuild on-failure settings."
  type = object({
    enabled             = optional(bool, true)
    continue_on_failure = optional(bool, true)
  })
  default = {
    enabled    = true
    on_failure = true
  }
}


variable "validation_lint_settings" {
  description = "Settings for the lint validation stage. Valid values for on_failure are the same as the codebuild on-failure settings."

  type = object({
    enabled            = optional(bool, true)
    contine_on_failure = optional(bool, true)
  })

  default = {
    enabled             = true
    continue_on_failure = true
  }

}
