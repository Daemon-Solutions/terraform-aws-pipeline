
module "notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "~> 6.0"

  slack_webhook_url = "https://hooks.slack.com/services/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"
  slack_channel     = "superdry-cicd"
  slack_username    = "codebuild-bot"
  sns_topic_name    = "${var.pipeline_name}-codebuild-slack-alerts"
}


locals {
  code_build_resource_arns = concat([
    for stage, _ in var.tags == "" ? local.validation_stages : local.conditional_validation_stages :
    module.validation[stage].codebuild_project.arn
    ],
    module.plan.codebuild_project.arn,
    module.apply.codebuild_project.arn
  )

  event_type_ids = [
    "codebuild-project-build-state-succeeded",
    "codebuild-project-build-state-failed",
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded"
  ]
}

resource "aws_codestarnotifications_notification_rule" "pipeline_updates" {
  detail_type    = "FULL"
  event_type_ids = local.event_type_ids
  name           = "slackNotification-${aws_codepipeline.this.name}"
  resource       = aws_codepipeline.this.arn

  target {
    address = aws_sns_topic.pipeline_updates.arn
    type    = "SNS"
  }

}



resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.codebuild_failed.name
  arn       = module.notify_slack.sns_topic_arn
  target_id = "SendToSlackSNS"
}
