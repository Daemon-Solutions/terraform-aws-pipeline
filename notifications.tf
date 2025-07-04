module "notifications" {
  count               = var.enable_notifications ? 1 : 0
  source              = "git@github.com:Daemon-Solutions/codestar-notifications.git?ref=v1.0.0"
  sns_topic_name      = "${var.pipeline_name}-pipeline-slack-alerts"
  codebuild_projects  = local.codebuild_projects
  codebuild_event_ids = var.codebuild_event_ids
  codepipeline_project = {
    name = aws_codepipeline.this.name
    arn  = aws_codepipeline.this.arn
  }
  codepipeline_event_ids   = var.codepipeline_event_ids
  notification_name_prefix = var.notification_name_prefix

}
