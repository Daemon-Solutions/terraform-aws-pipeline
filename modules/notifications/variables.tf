variable "sns_topic_name" {
  description = "SNS topic name for notifications"
  type        = string
}

variable "codebuild_projects" {
  description = "List of CodeBuild project to monitor"
  type        = map(string)
}

variable "codebuild_event_ids" {
  type = list(string)
}


variable "codepipeline_project" {
  description = "CodePipeline project to monitor"
  type = object({
    name = string
    arn  = string
  })
}

variable "codepipeline_event_ids" {
  type = list(string)
}
