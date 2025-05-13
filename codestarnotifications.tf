resource "aws_codestarnotifications_notification_rule" "pipeline_updates" {
  count          = length(var.codepipelines)
  detail_type    = "FULL"
  event_type_ids = var.event_type_ids
  name           = "slackNotification${var.codepipelines[count.index].name}"
  resource       = var.codepipelines[count.index].arn

  target {
    address = aws_sns_topic.pipeline_updates.arn
    type    = "SNS"
  }

}
