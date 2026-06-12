provider "grafana" {
  url  = "https://separationofconcerns0dev.grafana.net"
  auth = var.grafana_sa_token
}
