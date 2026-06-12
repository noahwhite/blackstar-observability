variable "grafana_sa_token" {
  description = "Grafana Cloud service account token"
  type        = string
  sensitive   = true
}

variable "alert_notification_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "noah@noahwhite.net"
}
