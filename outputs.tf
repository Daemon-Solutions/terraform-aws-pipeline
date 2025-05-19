output "notification_sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = try(module.notifications[0].sns_topic_arn, "")
}
