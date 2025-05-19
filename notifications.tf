locals {
  codebuild_projects = merge({
    for stage, _ in var.tags == "" ? local.validation_stages : local.conditional_validation_stages :
    module.validation[stage].codebuild_project.name => module.validation[stage].codebuild_project.arn
    },
    {
      (module.plan.codebuild_project.name)  = module.plan.codebuild_project.arn
      (module.apply.codebuild_project.name) = module.apply.codebuild_project.arn
  })

}
module "notifications" {
  count               = var.enable_notifications ? 1 : 0
  source              = "./modules/notifications"
  sns_topic_name      = "${var.pipeline_name}-pipeline-slack-alerts"
  codebuild_projects  = local.codebuild_projects
  codebuild_event_ids = var.codebuild_event_ids
  codepipeline_project = {
    name = aws_codepipeline.this.name
    arn  = aws_codepipeline.this.arn
  }
  codepipeline_event_ids = var.codepipeline_event_ids

}
