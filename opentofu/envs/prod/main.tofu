resource "grafana_folder" "blackstar" {
  title = "Blackstar"
}

data "grafana_data_source" "prometheus" {
  name = "grafanacloud-separationofconcerns0dev-prom"
}

data "grafana_data_source" "loki" {
  name = "grafanacloud-separationofconcerns0dev-logs"
}
