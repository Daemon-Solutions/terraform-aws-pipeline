resource "aws_sns_topic" "topic" {
  name = var.sns_topic_name
}

resource "aws_codestarnotifications_notification_rule" "codepipeline_updates" {
  detail_type    = "FULL"
  event_type_ids = var.codepipeline_event_ids
  name           = "slackNotification-${var.codepipeline_project.name}"
  resource       = var.codepipeline_project.arn

  target {
    address = aws_sns_topic.topic.arn
    type    = "SNS"
  }

}

resource "aws_codestarnotifications_notification_rule" "codebuild_updates" {
  for_each       = var.codebuild_projects
  detail_type    = "FULL"
  event_type_ids = var.codebuild_event_ids
  name           = "slackNotification-${each.key}"
  resource       = each.value

  target {
    address = aws_sns_topic.topic.arn
    type    = "SNS"
  }

}



resource "aws_sns_topic_policy" "pipeline_updates" {
  arn    = aws_sns_topic.topic.arn
  policy = data.aws_iam_policy_document.pipeline_updates_policy.json
}

data "aws_iam_policy_document" "pipeline_updates_policy" {
  statement {
    sid    = "codestar-notification"
    effect = "Allow"
    resources = [
      aws_sns_topic.topic.arn
    ]

    principals {
      identifiers = [
        "codestar-notifications.amazonaws.com"
      ]
      type = "Service"
    }
    actions = [
      "SNS:Publish"
    ]
  }

}
