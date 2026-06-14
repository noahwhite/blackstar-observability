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
          legendFormat = "{{ instance }} {{ chip_alias }} {{ sensor }}"
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
          { expr = "rate(node_network_receive_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Rx", refId = "A" },
          { expr = "rate(node_network_transmit_bytes_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Tx", refId = "B" },
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
          { expr = "rate(node_network_receive_errs_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Rx Errors", refId = "A" },
          { expr = "rate(node_network_transmit_errs_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Tx Errors", refId = "B" },
          { expr = "rate(node_network_receive_drop_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Rx Drops", refId = "C" },
          { expr = "rate(node_network_transmit_drop_total{job=\"integrations/unix\", instance=~\"$instance\", device!~\"lo|veth.*|docker.*|br-.*|tailscale.*\"}[5m])", legendFormat = "{{ instance }} {{ device }} Tx Drops", refId = "D" },
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
    ]
  })
}
