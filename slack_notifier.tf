
# module "notify_slack" {
#   source  = "terraform-aws-modules/notify-slack/aws"
#   version = "~> 6.0"
#
#   slack_webhook_url = var.slack_webhook_url
#   slack_channel     = "#your-channel-name"
#   slack_username    = "codebuild-bot"
#
#   sns_topic_name = "codebuild-slack-alerts"
# }


locals {
  validation_code_build_resource_arns = [

    for stage in var.tags == "" ? local.validation_stages : local.conditional_validation_stages :
    module.validation[stage].codebuild_project.arn
  ]
}

resource "aws_cloudwatch_event_rule" "codebuild_failed" {
  name        = "codebuild-failure-rule"
  description = "Trigger SNS on CodeBuild failure"
  event_pattern = jsonencode({
    "source" : ["aws.codebuild"],
    "detail-type" : ["CodeBuild Build State Change"],
    "resources" : concat([], local.validation_code_build_resource_arns),
    "detail" : {
      "build-status" : ["FAILED"]
    }
  })
}

# resource "aws_cloudwatch_event_target" "sns_target" {
#   rule      = aws_cloudwatch_event_rule.codebuild_failed.name
#   arn       = module.notify_slack.sns_topic_arn
#   target_id = "SendToSlackSNS"
# }
