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

  # Correctable PCIe AER counts are the LEADING indicator for the fatal atlantic
  # Thunderbolt NIC failures that drop a node off the Ceph net. On pve06 they ran
  # 7/2/5/3/1 per day across Aug 14-18 before going fatal on 2026-08-18, and
  # nothing was watching them — the first page was "Memory Usage Critical" ~43h
  # later, which was a second-order symptom (an orphaned ceph-mon leaking
  # 3.13 GiB/h), not the fault. PD #29 / OFF-633.
  #
  # Threshold: background is roughly 0.04-0.4 errors/hour per node, so >3 in an
  # hour is ~10x baseline and worth a look, without paging on the singleton
  # RxErr these links produce routinely.
  rule {
    name      = "PCIe Correctable AER Errors Rising"
    condition = "C"
    for       = "5m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "PCIe correctable AER errors rising on {{ $labels.instance }} ({{ $labels.device }}, {{ $labels.driver }})"
      description = "More than 3 correctable PCIe AER errors in the last hour. On the ed800g9 nodes this precedes a fatal, unrecoverable AER on the Thunderbolt->SFP+ 10G NIC, which partitions the node from the Ceph cluster network. Check 'dmesg -T | grep -i aer' and peer reachability on 10.10.10.0/24 — ping the neighbours, NOT the node's own IP: a dead atlantic still answers itself and still reports link up."
    }

    labels = {
      severity = "warning"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 3600
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "sum by (instance, device, driver) (increase(node_pcie_aer_errors_total{severity=\"correctable\"}[1h]))"
        legendFormat = "{{ instance }} {{ device }}"
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
          evaluator = { params = [3], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  # A non-correctable AER means the device is already gone — the kernel logs
  # "can't recover" / "device inaccessible" and only a reboot re-enumerates it.
  # Any increase at all is actionable, so this fires immediately rather than
  # waiting for a downstream symptom.
  rule {
    name      = "PCIe Fatal AER Error"
    condition = "C"
    for       = "1m"

    no_data_state  = "OK"
    exec_err_state = "Error"

    annotations = {
      summary     = "Fatal/non-fatal PCIe AER on {{ $labels.instance }} ({{ $labels.device }}, {{ $labels.driver }})"
      description = "An unrecoverable PCIe AER was reported. If this is the atlantic NIC or its Thunderbolt bridge, the node has lost the 10G Ceph network: expect its OSDs to go down/out and its ceph-mon to fall out of quorum and then leak ~3 GiB/h until the OOM killer takes it, every ~15h. Recovery is a reboot — AER recovery has already failed by this point, and 'ip link set enp8s0 down' just makes the netdev vanish. Stop guest VMs first, set nobackfill/norecover, and mask ceph-mon on the affected node if the reboot has to wait."
    }

    labels = {
      severity = "critical"
      team     = "blackstar"
    }

    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 900
        to   = 0
      }
      model = jsonencode({
        datasource   = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        editorMode   = "code"
        expr         = "sum by (instance, device, driver) (increase(node_pcie_aer_errors_total{severity=~\"fatal|nonfatal\"}[15m]))"
        legendFormat = "{{ instance }} {{ device }}"
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
          evaluator = { params = [0], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["B"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }
}
