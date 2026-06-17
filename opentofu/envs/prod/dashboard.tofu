resource "grafana_dashboard" "node_health" {
  folder = grafana_folder.blackstar.id
  config_json = jsonencode({
    title       = "Blackstar Node Health"
    description = "Proxmox node health: temperatures, CPU, memory, disk, network, ZFS"
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

      # =================================================================
      # Overview
      # =================================================================
      {
        type      = "row"
        title     = "Overview"
        gridPos   = { h = 1, w = 24, x = 0, y = 0 }
        collapsed = false
      },
      {
        id         = 1
        type       = "stat"
        title      = "CPU Pkg Temp"
        gridPos    = { h = 4, w = 4, x = 0, y = 1 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "area", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "max by (instance) (node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=\"platform_coretemp_0\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 2
        type       = "stat"
        title      = "Drive Max Temp"
        gridPos    = { h = 4, w = 4, x = 4, y = 1 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "area", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "max by (instance) (node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=~\"nvme_nvme.*|target.*\", sensor=\"temp1\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 3
        type       = "stat"
        title      = "CPU Usage"
        gridPos    = { h = 4, w = 4, x = 8, y = 1 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "area", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "1 - avg by (instance) (rate(node_cpu_seconds_total{job=\"integrations/unix\", instance=~\"$instance\", mode=\"idle\"}[5m]))"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 4
        type       = "stat"
        title      = "Memory Usage"
        gridPos    = { h = 4, w = 4, x = 12, y = 1 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "area", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "1 - (node_memory_MemAvailable_bytes{job=\"integrations/unix\", instance=~\"$instance\"} / node_memory_MemTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 5
        type       = "gauge"
        title      = "Root Disk"
        gridPos    = { h = 4, w = 4, x = 16, y = 1 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
        options = { reduceOptions = { calcs = ["lastNotNull"] }, orientation = "auto" }
        targets = [{
          expr         = "1 - (node_filesystem_avail_bytes{job=\"integrations/unix\", instance=~\"$instance\", mountpoint=\"/\"} / node_filesystem_size_bytes{job=\"integrations/unix\", instance=~\"$instance\", mountpoint=\"/\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 6
        type       = "stat"
        title      = "Uptime"
        gridPos    = { h = 4, w = 4, x = 20, y = 1 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit = "s"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "orange", value = null },
                { color = "green", value = 3600 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "none", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "time() - node_boot_time_seconds{job=\"integrations/unix\", instance=~\"$instance\"}"
          legendFormat = "{{ instance }}"
          refId        = "A"
          instant      = true
        }]
      },

      # =================================================================
      # Thermal Monitoring
      # =================================================================
      {
        type      = "row"
        title     = "Thermal Monitoring"
        gridPos   = { h = 1, w = 24, x = 0, y = 5 }
        collapsed = false
      },
      {
        id         = 10
        type       = "timeseries"
        title      = "CPU Core Temperatures"
        gridPos    = { h = 8, w = 6, x = 0, y = 6 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit       = "celsius"
            custom     = { drawStyle = "line", fillOpacity = 5 }
            thresholds = { mode = "absolute", steps = [{ color = "green", value = null }, { color = "red", value = 80 }] }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [{
          expr         = "node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=\"platform_coretemp_0\"}"
          legendFormat = "{{ instance }} {{ chip_alias }} {{ sensor }}"
          refId        = "A"
        }]
      },
      {
        id         = 13
        type       = "timeseries"
        title      = "CPU Fan Speed"
        gridPos    = { h = 8, w = 6, x = 6, y = 6 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit   = "rpm"
            custom = { drawStyle = "line", fillOpacity = 10 }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [{
          expr         = "node_hwmon_fan_rpm{job=\"integrations/unix\", instance=~\"$instance\"}"
          legendFormat = "{{ instance }} cpu fan"
          refId        = "A"
        }]
      },
      {
        id         = 11
        type       = "timeseries"
        title      = "Drive Temperatures"
        gridPos    = { h = 8, w = 6, x = 12, y = 6 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit       = "celsius"
            custom     = { drawStyle = "line", fillOpacity = 5 }
            thresholds = { mode = "absolute", steps = [{ color = "green", value = null }, { color = "red", value = 65 }] }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [{
          expr         = "node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=~\"nvme_nvme.*|target.*\"}"
          legendFormat = "{{ instance }} {{ chip_alias }} {{ sensor }}"
          refId        = "A"
        }]
      },
      {
        id         = 12
        type       = "timeseries"
        title      = "10Gb NIC Temperature"
        gridPos    = { h = 8, w = 6, x = 18, y = 6 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit   = "celsius"
            custom = { drawStyle = "line", fillOpacity = 5 }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [{
          expr         = "node_hwmon_temp_celsius{job=\"integrations/unix\", instance=~\"$instance\", chip=~\"0000:07.*\", sensor=\"temp2\"}"
          legendFormat = "{{ instance }} {{ chip_alias }} MAC"
          refId        = "A"
        }]
      },

      # =================================================================
      # System Resources
      # =================================================================
      {
        type      = "row"
        title     = "System Resources"
        gridPos   = { h = 1, w = 24, x = 0, y = 14 }
        collapsed = false
      },
      {
        id         = 20
        type       = "timeseries"
        title      = "CPU Usage"
        gridPos    = { h = 8, w = 12, x = 0, y = 15 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, max = 1, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "single" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [{
          expr         = "1 - avg by (instance) (rate(node_cpu_seconds_total{job=\"integrations/unix\", instance=~\"$instance\", mode=\"idle\"}[5m]))"
          legendFormat = "{{ instance }}"
          refId        = "A"
        }]
      },
      {
        id         = 21
        type       = "timeseries"
        title      = "Memory Usage"
        gridPos    = { h = 8, w = 12, x = 12, y = 15 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, max = 1, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "single" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [{
          expr         = "1 - (node_memory_MemAvailable_bytes{job=\"integrations/unix\", instance=~\"$instance\"} / node_memory_MemTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"})"
          legendFormat = "{{ instance }}"
          refId        = "A"
        }]
      },
      {
        id         = 22
        type       = "timeseries"
        title      = "System Load (1m / 5m / 15m)"
        gridPos    = { h = 8, w = 8, x = 0, y = 23 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { custom = { drawStyle = "line", fillOpacity = 5 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "node_load1{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} 1m", refId = "A" },
          { expr = "node_load5{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} 5m", refId = "B" },
          { expr = "node_load15{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} 15m", refId = "C" },
        ]
      },
      {
        id         = 24
        type       = "timeseries"
        title      = "CPU Frequency"
        gridPos    = { h = 8, w = 8, x = 8, y = 23 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "hertz", custom = { drawStyle = "line", fillOpacity = 5 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          {
            expr         = "avg by (instance) (node_cpu_scaling_frequency_hertz{job=\"integrations/unix\", instance=~\"$instance\"})"
            legendFormat = "{{ instance }} avg"
            refId        = "A"
          },
          {
            expr         = "max by (instance) (node_cpu_scaling_frequency_hertz{job=\"integrations/unix\", instance=~\"$instance\"})"
            legendFormat = "{{ instance }} max"
            refId        = "B"
          },
          {
            expr         = "min by (instance) (node_cpu_scaling_frequency_hertz{job=\"integrations/unix\", instance=~\"$instance\"})"
            legendFormat = "{{ instance }} min"
            refId        = "C"
          },
        ]
      },
      {
        id         = 25
        type       = "timeseries"
        title      = "CPU Thermal Throttle Events"
        gridPos    = { h = 8, w = 8, x = 16, y = 23 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "short", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          {
            expr         = "rate(node_cpu_package_throttles_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m])"
            legendFormat = "{{ instance }} package"
            refId        = "A"
          },
          {
            expr         = "sum by (instance) (rate(node_cpu_core_throttles_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m]))"
            legendFormat = "{{ instance }} cores"
            refId        = "B"
          },
        ]
      },
      {
        id         = 23
        type       = "timeseries"
        title      = "Memory Breakdown"
        gridPos    = { h = 8, w = 12, x = 0, y = 31 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bytes", custom = { drawStyle = "line", fillOpacity = 20, stacking = { mode = "normal" } } }
          overrides = []
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "node_memory_MemTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"} - node_memory_MemAvailable_bytes{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} Used", refId = "A" },
          { expr = "node_memory_Buffers_bytes{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} Buffers", refId = "B" },
          { expr = "node_memory_Cached_bytes{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} Cached", refId = "C" },
          { expr = "node_memory_MemFree_bytes{job=\"integrations/unix\", instance=~\"$instance\"}", legendFormat = "{{ instance }} Free", refId = "D" },
        ]
      },
      {
        id         = 26
        type       = "timeseries"
        title      = "Swap Usage"
        gridPos    = { h = 8, w = 12, x = 12, y = 31 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bytes", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          {
            expr         = "node_memory_SwapTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Total"
            refId        = "A"
          },
          {
            expr         = "node_memory_SwapTotal_bytes{job=\"integrations/unix\", instance=~\"$instance\"} - node_memory_SwapFree_bytes{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Used"
            refId        = "B"
          },
        ]
      },

      # =================================================================
      # ZFS
      # =================================================================
      {
        type      = "row"
        title     = "ZFS"
        gridPos   = { h = 1, w = 24, x = 0, y = 39 }
        collapsed = false
      },
      {
        id         = 50
        type       = "timeseries"
        title      = "ARC Size"
        gridPos    = { h = 8, w = 12, x = 0, y = 40 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bytes", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          {
            expr         = "node_zfs_arc_size{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Current"
            refId        = "A"
          },
          {
            expr         = "node_zfs_arc_c_max{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Max"
            refId        = "B"
          },
          {
            expr         = "node_zfs_arc_c_min{job=\"integrations/unix\", instance=~\"$instance\"}"
            legendFormat = "{{ instance }} Min"
            refId        = "C"
          },
        ]
      },
      {
        id         = 51
        type       = "timeseries"
        title      = "ARC Hit Ratio"
        gridPos    = { h = 8, w = 12, x = 12, y = 40 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, max = 1, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [{
          expr         = "rate(node_zfs_arc_hits{job=\"integrations/unix\", instance=~\"$instance\"}[5m]) / (rate(node_zfs_arc_hits{job=\"integrations/unix\", instance=~\"$instance\"}[5m]) + rate(node_zfs_arc_misses{job=\"integrations/unix\", instance=~\"$instance\"}[5m]))"
          legendFormat = "{{ instance }}"
          refId        = "A"
        }]
      },

      # =================================================================
      # Storage I/O
      # =================================================================
      {
        type      = "row"
        title     = "Storage I/O"
        gridPos   = { h = 1, w = 24, x = 0, y = 48 }
        collapsed = false
      },
      {
        id         = 40
        type       = "timeseries"
        title      = "Disk Throughput"
        gridPos    = { h = 8, w = 12, x = 0, y = 49 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "Bps", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = [{ matcher = { id = "byRegexp", options = ".*Write.*" }, properties = [{ id = "custom.transform", value = "negative-Y" }] }]
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "rate(node_disk_read_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device=~\"sda|nvme.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Read", refId = "A" },
          { expr = "rate(node_disk_written_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device=~\"sda|nvme.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Write", refId = "B" },
        ]
      },
      {
        id         = 41
        type       = "timeseries"
        title      = "Disk IOPS"
        gridPos    = { h = 8, w = 12, x = 12, y = 49 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "iops", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = [{ matcher = { id = "byRegexp", options = ".*Write.*" }, properties = [{ id = "custom.transform", value = "negative-Y" }] }]
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "rate(node_disk_reads_completed_total{job=\"integrations/unix\", instance=~\"$instance\", device=~\"sda|nvme.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Read", refId = "A" },
          { expr = "rate(node_disk_writes_completed_total{job=\"integrations/unix\", instance=~\"$instance\", device=~\"sda|nvme.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Write", refId = "B" },
        ]
      },
      {
        id         = 42
        type       = "timeseries"
        title      = "Disk Utilization"
        gridPos    = { h = 8, w = 24, x = 0, y = 57 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, max = 1, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [{
          expr         = "rate(node_disk_io_time_seconds_total{job=\"integrations/unix\", instance=~\"$instance\", device=~\"sda|nvme.*\"}[5m])"
          legendFormat = "{{ instance }} {{ device }}"
          refId        = "A"
        }]
      },

      # =================================================================
      # Network
      # =================================================================
      {
        type      = "row"
        title     = "Network"
        gridPos   = { h = 1, w = 24, x = 0, y = 65 }
        collapsed = false
      },
      {
        id         = 30
        type       = "timeseries"
        title      = "Network I/O"
        gridPos    = { h = 8, w = 12, x = 0, y = 66 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "Bps", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = [{ matcher = { id = "byRegexp", options = ".*Tx.*" }, properties = [{ id = "custom.transform", value = "negative-Y" }] }]
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "rate(node_network_receive_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*|wlp.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Rx", refId = "A" },
          { expr = "rate(node_network_transmit_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*|wlp.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Tx", refId = "B" },
        ]
      },
      {
        id         = 31
        type       = "timeseries"
        title      = "Network Errors & Drops"
        gridPos    = { h = 8, w = 12, x = 12, y = 66 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "short", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "rate(node_network_receive_errs_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*|wlp.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Rx Errors", refId = "A" },
          { expr = "rate(node_network_transmit_errs_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*|wlp.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Tx Errors", refId = "B" },
          { expr = "rate(node_network_receive_drop_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*|wlp.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Rx Drops", refId = "C" },
          { expr = "rate(node_network_transmit_drop_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*|wlp.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Tx Drops", refId = "D" },
        ]
      },

      # =================================================================
      # Resource Pressure (PSI)
      # =================================================================
      {
        type      = "row"
        title     = "Resource Pressure (PSI)"
        gridPos   = { h = 1, w = 24, x = 0, y = 74 }
        collapsed = false
      },
      {
        id         = 60
        type       = "timeseries"
        title      = "CPU Pressure"
        gridPos    = { h = 8, w = 8, x = 0, y = 75 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [{
          expr         = "rate(node_pressure_cpu_waiting_seconds_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m])"
          legendFormat = "{{ instance }} some"
          refId        = "A"
        }]
      },
      {
        id         = 61
        type       = "timeseries"
        title      = "Memory Pressure"
        gridPos    = { h = 8, w = 8, x = 8, y = 75 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "rate(node_pressure_memory_waiting_seconds_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m])", legendFormat = "{{ instance }} some", refId = "A" },
          { expr = "rate(node_pressure_memory_stalled_seconds_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m])", legendFormat = "{{ instance }} full", refId = "B" },
        ]
      },
      {
        id         = 62
        type       = "timeseries"
        title      = "I/O Pressure"
        gridPos    = { h = 8, w = 8, x = 16, y = 75 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "percentunit", min = 0, custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" }, legend = { displayMode = "list", placement = "bottom" } }
        targets = [
          { expr = "rate(node_pressure_io_waiting_seconds_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m])", legendFormat = "{{ instance }} some", refId = "A" },
          { expr = "rate(node_pressure_io_stalled_seconds_total{job=\"integrations/unix\", instance=~\"$instance\"}[5m])", legendFormat = "{{ instance }} full", refId = "B" },
        ]
      },

      # =================================================================
      # Network Switch (MikroTik CRS305)
      # =================================================================
      {
        type      = "row"
        title     = "Network Switch (CRS305)"
        gridPos   = { h = 1, w = 24, x = 0, y = 83 }
        collapsed = false
      },
      {
        id         = 70
        type       = "stat"
        title      = "Switch Temperature"
        gridPos    = { h = 4, w = 6, x = 0, y = 84 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit = "celsius"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 50 },
                { color = "orange", value = 60 },
                { color = "red", value = 70 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "area", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "mtxrHlProcessorTemperature{job=\"integrations/snmp/crs305\"} / 10"
          legendFormat = "CPU"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 71
        type       = "stat"
        title      = "Switch CPU Load"
        gridPos    = { h = 4, w = 6, x = 6, y = 84 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit = "percent"
            min  = 0
            max  = 100
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "yellow", value = 60 },
                { color = "orange", value = 80 },
                { color = "red", value = 95 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "area", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "hrProcessorLoad{job=\"integrations/snmp/crs305\"}"
          legendFormat = "CPU"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 72
        type       = "gauge"
        title      = "Switch Memory"
        gridPos    = { h = 4, w = 6, x = 12, y = 84 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
                { color = "red", value = 0.9 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, orientation = "auto" }
        targets = [{
          expr         = "hrStorageUsed{job=\"integrations/snmp/crs305\",hrStorageDescr=\"main memory\"} / hrStorageSize{job=\"integrations/snmp/crs305\",hrStorageDescr=\"main memory\"}"
          legendFormat = "Used"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 73
        type       = "stat"
        title      = "Switch Uptime"
        gridPos    = { h = 4, w = 6, x = 18, y = 84 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit = "s"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "orange", value = null },
                { color = "green", value = 3600 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "none", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "sysUpTime{job=\"integrations/snmp/crs305\"} / 100"
          legendFormat = "Uptime"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 74
        type       = "timeseries"
        title      = "Switch Port Traffic"
        gridPos    = { h = 8, w = 12, x = 0, y = 88 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bps", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = [{ matcher = { id = "byRegexp", options = ".*Tx.*" }, properties = [{ id = "custom.transform", value = "negative-Y" }] }]
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull"] } }
        targets = [
          { expr = "rate(ifHCInOctets{job=\"integrations/snmp/crs305\"}[$__rate_interval]) * 8", legendFormat = "{{ ifDescr }} Rx", refId = "A" },
          { expr = "rate(ifHCOutOctets{job=\"integrations/snmp/crs305\"}[$__rate_interval]) * 8", legendFormat = "{{ ifDescr }} Tx", refId = "B" },
        ]
      },
      {
        id         = 75
        type       = "timeseries"
        title      = "Switch Temperature History"
        gridPos    = { h = 8, w = 6, x = 12, y = 88 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit       = "celsius"
            custom     = { drawStyle = "line", fillOpacity = 5 }
            thresholds = { mode = "absolute", steps = [{ color = "green", value = null }, { color = "red", value = 70 }] }
          }
          overrides = []
        }
        options = {
          tooltip = { mode = "multi", sort = "desc" }
          legend  = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull", "max"] }
        }
        targets = [
          {
            expr         = "mtxrHlProcessorTemperature{job=\"integrations/snmp/crs305\"} / 10"
            legendFormat = "CPU"
            refId        = "A"
          },
        ]
      },
      {
        id         = 76
        type       = "gauge"
        title      = "Switch Disk"
        gridPos    = { h = 8, w = 6, x = 18, y = 88 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
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
                { color = "red", value = 0.9 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, orientation = "auto" }
        targets = [{
          expr         = "hrStorageUsed{job=\"integrations/snmp/crs305\",hrStorageDescr=\"system disk\"} / hrStorageSize{job=\"integrations/snmp/crs305\",hrStorageDescr=\"system disk\"}"
          legendFormat = "Used"
          refId        = "A"
          instant      = true
        }]
      },
      # =================================================================
      # Top-of-Rack Switch (TP-Link SG2210P)
      # =================================================================
      {
        type      = "row"
        title     = "Top-of-Rack Switch (SG2210P)"
        gridPos   = { h = 1, w = 24, x = 0, y = 96 }
        collapsed = false
      },
      {
        id         = 80
        type       = "stat"
        title      = "TOR Uptime"
        gridPos    = { h = 7, w = 4, x = 0, y = 97 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit = "s"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "orange", value = null },
                { color = "green", value = 3600 },
              ]
            }
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, graphMode = "none", colorMode = "value", textMode = "auto" }
        targets = [{
          expr         = "sysUpTime{job=\"integrations/snmp/sg2210p\"} / 100"
          legendFormat = "Uptime"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 81
        type       = "canvas"
        title      = "SG2210P Port Map"
        gridPos    = { h = 7, w = 16, x = 4, y = 97 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            color = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "#444", value = null },
                { color = "green", value = 1 },
                { color = "red", value = 2 },
              ]
            }
          }
          overrides = []
        }
        options = {
          inlineEditing = false
          panZoom       = false
          root = {
            type = "frame"
            name = "root"
            elements = [
              {
                type = "rectangle"
                name = "switch-bg"
                background = {
                  image = { mode = "fixed", fixed = "https://raw.githubusercontent.com/noahwhite/blackstar-observability/feature/sg2210p-dashboard/assets/sg2210p-rear.png" }
                  size  = "fill"
                }
                placement  = { top = 0, left = 0, width = 755, height = 180 }
                constraint = { horizontal = "left", vertical = "top" }
              },
              { type = "rectangle", name = "port-8", background = { color = { field = "gigabitEthernet 1/0/8", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 142, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-7", background = { color = { field = "gigabitEthernet 1/0/7", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 194, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-6", background = { color = { field = "gigabitEthernet 1/0/6", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 246, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-5", background = { color = { field = "gigabitEthernet 1/0/5", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 296, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-4", background = { color = { field = "gigabitEthernet 1/0/4", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 348, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-3", background = { color = { field = "gigabitEthernet 1/0/3", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 400, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-2", background = { color = { field = "gigabitEthernet 1/0/2", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 450, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-1", background = { color = { field = "gigabitEthernet 1/0/1", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 97, left = 502, width = 21, height = 19 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-9", background = { color = { field = "gigabitEthernet 1/0/9", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 100, left = 571, width = 25, height = 15 }, constraint = { horizontal = "left", vertical = "top" } },
              { type = "rectangle", name = "port-10", background = { color = { field = "gigabitEthernet 1/0/10", fixed = "#333" } }, border = { color = { fixed = "transparent" }, width = 0 }, placement = { top = 100, left = 648, width = 24, height = 15 }, constraint = { horizontal = "left", vertical = "top" } },
            ]
          }
        }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/sg2210p\",ifDescr=~\"gigabitEthernet.*\"}"
          legendFormat = "{{ ifDescr }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 82
        type       = "timeseries"
        title      = "TOR Port Traffic"
        gridPos    = { h = 8, w = 24, x = 0, y = 104 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bps", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = [{ matcher = { id = "byRegexp", options = ".*Tx.*" }, properties = [{ id = "custom.transform", value = "negative-Y" }] }]
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull"] } }
        targets = [
          { expr = "rate(ifHCInOctets{job=\"integrations/snmp/sg2210p\",ifDescr=~\"gigabitEthernet.*\"}[$__rate_interval]) * 8", legendFormat = "{{ ifDescr }} Rx", refId = "A" },
          { expr = "rate(ifHCOutOctets{job=\"integrations/snmp/sg2210p\",ifDescr=~\"gigabitEthernet.*\"}[$__rate_interval]) * 8", legendFormat = "{{ ifDescr }} Tx", refId = "B" },
        ]
      },
    ]
  })
}
