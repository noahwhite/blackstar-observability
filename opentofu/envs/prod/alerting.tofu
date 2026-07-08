resource "grafana_contact_point" "email" {
  name = "Email - Blackstar"

  email {
    addresses               = [var.alert_notification_email]
    single_email            = true
    disable_resolve_message = false
  }
}

resource "grafana_notification_policy" "root" {
  contact_point = grafana_contact_point.email.name
  group_by      = ["grafana_folder", "alertname"]
}

resource "grafana_rule_group" "node_health" {
  folder_uid       = grafana_folder.blackstar.uid
  name             = "Node Health"
  interval_seconds = 60

  rule {
    name      = "CPU Temperature High"
    condition = "C"
    for       = "5m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "CPU package temperature > 80°C on {{ $labels.instance }}"
      description = "Sustained high CPU temperature on a passively-cooled EliteDesk G9 Mini. Check airflow and ambient temperature."
    }

    labels = {
      severity = "warning"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "max by (instance) (node_hwmon_temp_celsius{job=\"integrations/unix\", chip=\"platform_coretemp_0\"})"
        legendFormat = "{{ instance }}"
        refId        = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "A"
        reducer    = "last"
        refId      = "B"
        type       = "reduce"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
        conditions = [{
          evaluator = { params = [80], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  rule {
    name      = "Drive Temperature High"
    condition = "C"
    for       = "5m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "Drive temperature > 65°C on {{ $labels.instance }} ({{ $labels.chip }})"
      description = "Drive running hot. NVMe/SATA drives typically throttle at 70-75°C. Check airflow."
    }

    labels = {
      severity = "warning"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "max by (instance, chip) (node_hwmon_temp_celsius{job=\"integrations/unix\", chip=~\"nvme_nvme.*|target.*\", sensor=\"temp1\"})"
        legendFormat = "{{ instance }} {{ chip }}"
        refId        = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "A"
        reducer    = "last"
        refId      = "B"
        type       = "reduce"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
        conditions = [{
          evaluator = { params = [65], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  rule {
    name      = "CPU Usage Critical"
    condition = "C"
    for       = "10m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "CPU usage > 90% on {{ $labels.instance }} for 10 minutes"
      description = "Sustained high CPU on Proxmox node. VMs and containers may be starved."
    }

    labels = {
      severity = "warning"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "1 - avg by (instance) (rate(node_cpu_seconds_total{job=\"integrations/unix\", mode=\"idle\"}[5m]))"
        legendFormat = "{{ instance }}"
        refId        = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "A"
        reducer    = "last"
        refId      = "B"
        type       = "reduce"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
        conditions = [{
          evaluator = { params = [0.9], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  rule {
    name      = "Memory Usage Critical"
    condition = "C"
    for       = "5m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "Memory usage > 85% on {{ $labels.instance }}"
      description = "High memory pressure on Proxmox node. Risk of OOM kills for VMs and containers."
    }

    labels = {
      severity = "warning"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "1 - (node_memory_MemAvailable_bytes{job=\"integrations/unix\"} / node_memory_MemTotal_bytes{job=\"integrations/unix\"})"
        legendFormat = "{{ instance }}"
        refId        = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "A"
        reducer    = "last"
        refId      = "B"
        type       = "reduce"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
        conditions = [{
          evaluator = { params = [0.85], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  rule {
    name      = "Root Disk Usage Critical"
    condition = "C"
    for       = "5m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "Root disk usage > 80% on {{ $labels.instance }}"
      description = "ZFS root pool filling up. Investigate large files or snapshots."
    }

    labels = {
      severity = "critical"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "1 - (node_filesystem_avail_bytes{job=\"integrations/unix\", mountpoint=\"/\"} / node_filesystem_size_bytes{job=\"integrations/unix\", mountpoint=\"/\"})"
        legendFormat = "{{ instance }}"
        refId        = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "A"
        reducer    = "last"
        refId      = "B"
        type       = "reduce"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
        conditions = [{
          evaluator = { params = [0.8], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  rule {
    name      = "Switch Temperature High"
    condition = "C"
    for       = "5m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "Switch temperature > 60°C on {{ $labels.job }}"
      description = "Sustained high temperature on a fanless MikroTik switch. Check rack airflow and ambient temperature."
    }

    labels = {
      severity = "warning"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "max by (job) (mtxrHlSensorValue{job=~\"integrations/snmp/(crs305|css610)\"})"
        legendFormat = "{{ job }}"
        refId        = "A"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "A"
        reducer    = "last"
        refId      = "B"
        type       = "reduce"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        datasource = { type = "__expr__", uid = "__expr__" }
        expression = "B"
        refId      = "C"
        type       = "threshold"
        conditions = [{
          evaluator = { params = [60], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }
}
