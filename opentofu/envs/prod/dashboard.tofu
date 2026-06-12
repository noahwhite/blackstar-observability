resource "grafana_dashboard" "node_health" {
  folder = grafana_folder.blackstar.id
  config_json = jsonencode({
    title       = "Blackstar Node Health"
    description = "Proxmox node health: temperatures, CPU, memory, disk, network"
    editable    = true
    tags        = ["blackstar", "proxmox"]
    refresh     = "1m"
    time = {
      from = "now-3h"
      to   = "now"
    }

    templating = {
      list = [{
        type       = "query"
        name       = "instance"
        label      = "Node"
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        query      = "label_values(up{job=\"integrations/unix\"}, instance)"
        refresh    = 2
        sort       = 1
        includeAll = true
        multi      = true
        current    = { text = "All", value = "$__all" }
      }]
    }

    panels = [
      {
        type      = "row"
        title     = "Overview"
        gridPos   = { h = 1, w = 24, x = 0, y = 0 }
        collapsed = false
      },

      {
        id      = 1
        type    = "stat"
        title   = "CPU Package Temp"
        gridPos = { h = 4, w = 5, x = 0, y = 1 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "celsius"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 65 },
                { color = "orange", value = 75 },
                { color = "red", value = 85 },
              ]
            }
          }
          overrides = []
        }
        options = {
          reduceOptions = { calcs = ["lastNotNull"] }
          graphMode     = "area"
          colorMode     = "value"
          textMode      = "auto"
        }
        targets = [{
          expr         = "max by (instance) (node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=\"platform_coretemp_0\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },

      {
        id      = 2
        type    = "stat"
        title   = "NVMe Max Temp"
        gridPos = { h = 4, w = 5, x = 5, y = 1 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "celsius"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 55 },
                { color = "orange", value = 65 },
                { color = "red", value = 70 },
              ]
            }
          }
          overrides = []
        }
        options = {
          reduceOptions = { calcs = ["lastNotNull"] }
          graphMode     = "area"
          colorMode     = "value"
          textMode      = "auto"
        }
        targets = [{
          expr         = "max by (instance) (node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=~\"nvme_nvme.*\", sensor=\"temp1\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },

      {
        id      = 3
        type    = "stat"
        title   = "CPU Usage"
        gridPos = { h = 4, w = 5, x = 10, y = 1 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "percentunit"
            min  = 0
            max  = 1
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 0.7 },
                { color = "orange", value = 0.85 },
                { color = "red", value = 0.95 },
              ]
            }
          }
          overrides = []
        }
        options = {
          reduceOptions = { calcs = ["lastNotNull"] }
          graphMode     = "area"
          colorMode     = "value"
          textMode      = "auto"
        }
        targets = [{
          expr         = "1 - avg by (instance) (rate(node_cpu_seconds_total{job=\"integrations/unix\", instance=~\"$instance\", mode=\"idle\"}[5m]))"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },

      {
        id      = 4
        type    = "stat"
        title   = "Memory Usage"
        gridPos = { h = 4, w = 5, x = 15, y = 1 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "percentunit"
            min  = 0
            max  = 1
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 0.7 },
                { color = "orange", value = 0.85 },
                { color = "red", value = 0.95 },
              ]
            }
          }
          overrides = []
        }
        options = {
          reduceOptions = { calcs = ["lastNotNull"] }
          graphMode     = "area"
          colorMode     = "value"
          textMode      = "auto"
        }
        targets = [{
          expr         = "1 - (node_memory_MemAvailable_bytes{job=\"integrations/unix\", instance=~\"$instance\"} / node_memory_MemTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },

      {
        id      = 5
        type    = "gauge"
        title   = "Root Disk Usage"
        gridPos = { h = 4, w = 4, x = 20, y = 1 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit = "percentunit"
            min  = 0
            max  = 1
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 0.7 },
                { color = "red", value = 0.8 },
              ]
            }
          }
          overrides = []
        }
        options = {
          reduceOptions = { calcs = ["lastNotNull"] }
          orientation   = "auto"
        }
        targets = [{
          expr         = "1 - (node_filesystem_avail_bytes{job=\"integrations/unix\", instance=~\"$instance\", mountpoint=\"/\"} / node_filesystem_size_bytes{job=\"integrations/unix\", instance=~\"$instance\", mountpoint=\"/\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },

      {
        type      = "row"
        title     = "Thermal Monitoring"
        gridPos   = { h = 1, w = 24, x = 0, y = 5 }
        collapsed = false
      },

      {
        id      = 10
        type    = "timeseries"
        title   = "CPU Core Temperatures"
        gridPos = { h = 8, w = 12, x = 0, y = 6 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit   = "celsius"
            custom = { drawStyle = "line", fillOpacity = 5 }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "red", value = 80 },
              ]
            }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [{
          expr         = "node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=\"platform_coretemp_0\"}"
          legendFormat = "{{ instance }} {{ sensor }}"
          refId        = "A"
        }]
      },

      {
        id      = 11
        type    = "timeseries"
        title   = "NVMe Drive Temperatures"
        gridPos = { h = 8, w = 12, x = 12, y = 6 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit   = "celsius"
            custom = { drawStyle = "line", fillOpacity = 5 }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "red", value = 65 },
              ]
            }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [{
          expr         = "node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=~\"nvme_nvme.*\"}"
          legendFormat = "{{ instance }} {{ chip }} {{ sensor }}"
          refId        = "A"
        }]
      },

      {
        type      = "row"
        title     = "System Resources"
        gridPos   = { h = 1, w = 24, x = 0, y = 14 }
        collapsed = false
      },

      {
        id      = 20
        type    = "timeseries"
        title   = "CPU Usage"
        gridPos = { h = 8, w = 12, x = 0, y = 15 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit   = "percentunit"
            min    = 0
            max    = 1
            custom = { drawStyle = "line", fillOpacity = 10 }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "single" }
          legend  = { displayMode = "list", placement = "bottom" }
        }
        targets = [{
          expr         = "1 - avg by (instance) (rate(node_cpu_seconds_total{job=\"integrations/unix\", instance=~\"$instance\", mode=\"idle\"}[5m]))"
          legendFormat = "{{ instance }}"
          refId        = "A"
        }]
      },

      {
        id      = 21
        type    = "timeseries"
        title   = "Memory Usage"
        gridPos = { h = 8, w = 12, x = 12, y = 15 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit   = "percentunit"
            min    = 0
            max    = 1
            custom = { drawStyle = "line", fillOpacity = 10 }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "single" }
          legend  = { displayMode = "list", placement = "bottom" }
        }
        targets = [{
          expr         = "1 - (node_memory_MemAvailable_bytes{job=\"integrations/unix\", instance=~\"$instance\"} / node_memory_MemTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
        }]
      },

      {
        id      = 22
        type    = "timeseries"
        title   = "System Load (1m / 5m / 15m)"
        gridPos = { h = 8, w = 12, x = 0, y = 23 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            custom = { drawStyle = "line", fillOpacity = 5 }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi" }
          legend  = { displayMode = "list", placement = "bottom" }
        }
        targets = [
          {
            expr         = "node_load1{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} 1m"
            refId        = "A"
          },
          {
            expr         = "node_load5{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} 5m"
            refId        = "B"
          },
          {
            expr         = "node_load15{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} 15m"
            refId        = "C"
          },
        ]
      },

      {
        id      = 23
        type    = "timeseries"
        title   = "Memory Breakdown"
        gridPos = { h = 8, w = 12, x = 12, y = 23 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit   = "bytes"
            custom = { drawStyle = "line", fillOpacity = 20, stacking = { mode = "normal" } }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "list", placement = "bottom" }
        }
        targets = [
          {
            expr         = "node_memory_MemTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"} - node_memory_MemAvailable_bytes{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Used"
            refId        = "A"
          },
          {
            expr         = "node_memory_Buffers_bytes{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Buffers"
            refId        = "B"
          },
          {
            expr         = "node_memory_Cached_bytes{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Cached"
            refId        = "C"
          },
          {
            expr         = "node_memory_MemFree_bytes{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Free"
            refId        = "D"
          },
        ]
      },

      {
        type      = "row"
        title     = "Network"
        gridPos   = { h = 1, w = 24, x = 0, y = 31 }
        collapsed = false
      },

      {
        id      = 30
        type    = "timeseries"
        title   = "Network I/O"
        gridPos = { h = 8, w = 24, x = 0, y = 32 }
        datasource = {
          type = "prometheus"
          uid  = data.grafana_data_source.prometheus.uid
        }
        fieldConfig = {
          defaults = {
            unit   = "Bps"
            custom = { drawStyle = "line", fillOpacity = 10 }
          }
          overrides = [
            {
              matcher    = { id = "byRegexp", options = ".*Tx.*" }
              properties = [{ id = "custom.transform", value = "negative-Y" }]
            }
          ]
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "list", placement = "bottom" }
        }
        targets = [
          {
            expr         = "rate(node_network_receive_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])"
            legendFormat = "{{ instance }} {{ device }} Rx"
            refId        = "A"
          },
          {
            expr         = "rate(node_network_transmit_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])"
            legendFormat = "{{ instance }} {{ device }} Tx"
            refId        = "B"
          },
        ]
      },
    ]
  })
}
