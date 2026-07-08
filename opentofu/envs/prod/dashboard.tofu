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
      list = [
        {
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
        },
        {
          type       = "query"
          name       = "crs305_port"
          label      = "CRS305 Port"
          datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
          query      = "label_values(ifOperStatus{job=\"integrations/snmp/crs305\"}, ifDescr)"
          refresh    = 1
          sort       = 1
          current    = { text = "ether1", value = "ether1" }
        },
        {
          type       = "query"
          name       = "css610_port"
          label      = "CSS610 Port"
          datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
          query      = "label_values(ifOperStatus{job=\"integrations/snmp/css610\"}, ifDescr)"
          refresh    = 1
          sort       = 1
          current    = { text = "Port1", value = "Port1" }
        },
      ]
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
        id         = 83
        type       = "gapit-htmlgraphics-panel"
        title      = "CRS305 Port Map"
        gridPos    = { h = 5, w = 13, x = 5, y = 88 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = {}
          overrides = []
        }
        options = {
          add100Percentage          = true
          centerAlignContent        = true
          SVGBaseFix                = true
          renderOnMount             = true
          dynamicData               = true
          dynamicFieldDisplayValues = false
          dynamicHtmlGraphics       = false
          dynamicProps              = false
          panelupdateOnMount        = true
          overflow                  = "hidden"

          css = <<-EOT
          .switch-wrapper {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
          }
          .switch-container {
            position: relative;
            max-width: 100%;
            max-height: 100%;
            width: 100%;
          }
          .switch-bg {
            display: block;
            width: 100%;
            height: 100%;
          }
          .port-overlay {
            position: absolute;
            cursor: pointer;
            border-radius: 2px;
            transition: all 0.15s ease;
            opacity: 0.5;
            background-color: #444;
            box-sizing: border-box;
            border: 2px solid transparent;
          }
          .port-overlay:hover {
            opacity: 0.9;
            box-shadow: 0 0 8px rgba(255,255,255,0.6);
          }
          .port-overlay.selected {
            border-color: #fff;
            box-shadow: 0 0 10px rgba(255,255,255,0.7);
            opacity: 0.9;
          }
          EOT

          html = <<-EOT
          <div class="switch-wrapper">
            <div class="switch-container" style="aspect-ratio:675/145">
              <img src="https://raw.githubusercontent.com/noahwhite/blackstar-observability/1d1249da004502b00b424ef61d0c4c9357073d0f/assets/crs305-front.png" class="switch-bg" />
              <div class="port-overlay" data-port="ether1" title="ether1" style="left:9.19%;top:39.31%;width:7.11%;height:20.00%"></div>
              <div class="port-overlay" data-port="sfp-sfpplus1" title="sfp-sfpplus1" style="left:26.52%;top:48.97%;width:6.81%;height:15.86%"></div>
              <div class="port-overlay" data-port="sfp-sfpplus2" title="sfp-sfpplus2" style="left:44.15%;top:48.97%;width:6.81%;height:15.86%"></div>
              <div class="port-overlay" data-port="sfp-sfpplus3" title="sfp-sfpplus3" style="left:61.93%;top:48.97%;width:6.81%;height:15.86%"></div>
              <div class="port-overlay" data-port="sfp-sfpplus4" title="sfp-sfpplus4" style="left:79.70%;top:48.97%;width:6.81%;height:15.86%"></div>
            </div>
          </div>
          EOT

          onInit = <<-EOT
          htmlNode.querySelectorAll('.port-overlay').forEach(function(el) {
            el.addEventListener('click', function() {
              var update = {};
              update['var-crs305_port'] = el.dataset.port;
              htmlGraphics.locationService.partial(update, true);
              htmlNode.querySelectorAll('.port-overlay').forEach(function(o) {
                o.classList.toggle('selected', o.dataset.port === el.dataset.port);
              });
            });
          });
          EOT

          onRender = <<-EOT
          var statusMap = {};
          if (data && data.series) {
            data.series.forEach(function(s) {
              s.fields.forEach(function(f) {
                if (f.type !== 'number' || !f.values || f.values.length === 0) return;
                var val = Number(f.values[f.values.length - 1]);
                var name = null;
                if (f.labels && f.labels.ifDescr) name = f.labels.ifDescr;
                if (!name && f.config && f.config.displayNameFromDS) name = f.config.displayNameFromDS;
                if (!name && f.name && f.name !== 'Value' && f.name !== 'Time') name = f.name;
                if (!name && s.name) name = s.name;
                if (name) statusMap[name] = val;
              });
            });
          }
          var params = new URLSearchParams(window.location.search);
          var selected = params.get('var-crs305_port');
          htmlNode.querySelectorAll('.port-overlay').forEach(function(el) {
            var port = el.dataset.port;
            var status = statusMap[port];
            if (status === 1) {
              el.style.backgroundColor = 'rgba(115, 191, 105, 0.8)';
              el.style.opacity = '0.8';
            } else if (status === 2) {
              el.style.backgroundColor = 'rgba(242, 73, 92, 0.8)';
              el.style.opacity = '0.8';
            } else {
              el.style.backgroundColor = 'rgba(100, 100, 100, 0.6)';
              el.style.opacity = '0.6';
            }
            el.classList.toggle('selected', port === selected);
          });
          EOT
        }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/crs305\"}"
          legendFormat = "{{ ifDescr }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 74
        type       = "timeseries"
        title      = "Switch Port Traffic"
        gridPos    = { h = 8, w = 12, x = 0, y = 93 }
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
        gridPos    = { h = 8, w = 12, x = 12, y = 93 }
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
        gridPos    = { h = 5, w = 5, x = 0, y = 88 }
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

      # CRS305 Port Detail (drill-down from port map clicks)
      {
        id         = 84
        type       = "timeseries"
        title      = "Port Traffic — $crs305_port"
        gridPos    = { h = 8, w = 16, x = 0, y = 101 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bps", color = { mode = "palette-classic" } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" } }
        targets = [
          { expr = "rate(ifHCInOctets{job=\"integrations/snmp/crs305\",ifDescr=\"$crs305_port\"}[$__rate_interval]) * 8", legendFormat = "$crs305_port Rx", refId = "A" },
          { expr = "rate(ifHCOutOctets{job=\"integrations/snmp/crs305\",ifDescr=\"$crs305_port\"}[$__rate_interval]) * 8", legendFormat = "$crs305_port Tx", refId = "B" },
        ]
      },
      {
        id         = 85
        type       = "stat"
        title      = "Port Status"
        gridPos    = { h = 4, w = 4, x = 16, y = 101 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            color = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "green", value = 1 },
                { color = "red", value = 2 },
              ]
            }
            mappings = [
              { type = "value", options = { "1" = { text = "Up", color = "green" }, "2" = { text = "Down", color = "red" } } },
            ]
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, colorMode = "background" }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/crs305\",ifDescr=\"$crs305_port\"}"
          legendFormat = "Status"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 86
        type       = "stat"
        title      = "Link Speed"
        gridPos    = { h = 4, w = 4, x = 20, y = 101 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit  = "Mbps"
            color = { mode = "thresholds" }
            thresholds = {
              mode  = "absolute"
              steps = [{ color = "blue", value = null }]
            }
          }
          overrides = []
        }
        targets = [{
          expr         = "ifHighSpeed{job=\"integrations/snmp/crs305\",ifDescr=\"$crs305_port\"}"
          legendFormat = "Speed"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 87
        type       = "timeseries"
        title      = "Port Status History"
        gridPos    = { h = 4, w = 8, x = 16, y = 105 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            color = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "green", value = 1 },
                { color = "red", value = 2 },
              ]
            }
            mappings = [
              { type = "value", options = { "1" = { text = "Up", color = "green" }, "2" = { text = "Down", color = "red" } } },
            ]
            min = 0
            max = 3
          }
          overrides = []
        }
        options = { tooltip = { mode = "single" } }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/crs305\",ifDescr=\"$crs305_port\"}"
          legendFormat = "Status"
          refId        = "A"
        }]
      },

      # =================================================================
      # Management Switch (MikroTik CSS610)
      # =================================================================
      {
        type      = "row"
        title     = "Management Switch (CSS610)"
        gridPos   = { h = 1, w = 24, x = 0, y = 110 }
        collapsed = false
      },
      {
        id         = 80
        type       = "stat"
        title      = "CSS610 Uptime"
        gridPos    = { h = 6, w = 4, x = 0, y = 111 }
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
          expr         = "sysUpTime{job=\"integrations/snmp/css610\"} / 100"
          legendFormat = "Uptime"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 81
        type       = "gapit-htmlgraphics-panel"
        title      = "CSS610 Port Map"
        gridPos    = { h = 6, w = 16, x = 4, y = 111 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = {}
          overrides = []
        }
        options = {
          add100Percentage          = true
          centerAlignContent        = true
          SVGBaseFix                = true
          renderOnMount             = true
          dynamicData               = true
          dynamicFieldDisplayValues = false
          dynamicHtmlGraphics       = false
          dynamicProps              = false
          panelupdateOnMount        = true
          overflow                  = "hidden"

          css = <<-EOT
          .switch-wrapper {
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
          }
          .switch-container {
            position: relative;
            max-width: 100%;
            max-height: 100%;
            width: 100%;
          }
          .switch-bg {
            display: block;
            width: 100%;
            height: 100%;
          }
          .port-overlay {
            position: absolute;
            cursor: pointer;
            border-radius: 2px;
            transition: all 0.15s ease;
            opacity: 0.5;
            background-color: #444;
            box-sizing: border-box;
            border: 2px solid transparent;
          }
          .port-overlay:hover {
            opacity: 0.9;
            box-shadow: 0 0 8px rgba(255,255,255,0.6);
          }
          .port-overlay.selected {
            border-color: #fff;
            box-shadow: 0 0 10px rgba(255,255,255,0.7);
            opacity: 0.9;
          }
          EOT

          html = <<-EOT
          <div class="switch-wrapper">
            <div class="switch-container" style="aspect-ratio:530/114">
              <img src="https://raw.githubusercontent.com/noahwhite/blackstar-observability/main/assets/css610-front.jpg" class="switch-bg" />
              <div class="port-overlay" data-port="Port2" title="Port2" style="left:47.4%;top:31%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port1" title="Port1" style="left:47.4%;top:63%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port4" title="Port4" style="left:55.4%;top:31%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port3" title="Port3" style="left:55.4%;top:63%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port6" title="Port6" style="left:63.4%;top:31%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port5" title="Port5" style="left:63.4%;top:63%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port8" title="Port8" style="left:71.4%;top:31%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="Port7" title="Port7" style="left:71.4%;top:63%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="SFP+1" title="SFP+1" style="left:82%;top:68%;width:4%;height:10%"></div>
              <div class="port-overlay" data-port="SFP+2" title="SFP+2" style="left:91%;top:68%;width:4%;height:10%"></div>
            </div>
          </div>
          EOT

          onInit = <<-EOT
          htmlNode.querySelectorAll('.port-overlay').forEach(function(el) {
            el.addEventListener('click', function() {
              var update = {};
              update['var-css610_port'] = el.dataset.port;
              htmlGraphics.locationService.partial(update, true);
              htmlNode.querySelectorAll('.port-overlay').forEach(function(o) {
                o.classList.toggle('selected', o.dataset.port === el.dataset.port);
              });
            });
          });
          EOT

          onRender = <<-EOT
          var statusMap = {};
          if (data && data.series) {
            data.series.forEach(function(s) {
              s.fields.forEach(function(f) {
                if (f.type !== 'number' || !f.values || f.values.length === 0) return;
                var val = Number(f.values[f.values.length - 1]);
                var name = null;
                if (f.labels && f.labels.ifDescr) name = f.labels.ifDescr;
                if (!name && f.config && f.config.displayNameFromDS) name = f.config.displayNameFromDS;
                if (!name && f.name && f.name !== 'Value' && f.name !== 'Time') name = f.name;
                if (!name && s.name) name = s.name;
                if (name) statusMap[name] = val;
              });
            });
          }
          var params = new URLSearchParams(window.location.search);
          var selected = params.get('var-css610_port');
          htmlNode.querySelectorAll('.port-overlay').forEach(function(el) {
            var port = el.dataset.port;
            var status = statusMap[port];
            if (status === 1) {
              el.style.backgroundColor = 'rgba(115, 191, 105, 0.8)';
              el.style.opacity = '0.8';
            } else if (status === 2) {
              el.style.backgroundColor = 'rgba(242, 73, 92, 0.8)';
              el.style.opacity = '0.8';
            } else {
              el.style.backgroundColor = 'rgba(100, 100, 100, 0.6)';
              el.style.opacity = '0.6';
            }
            el.classList.toggle('selected', port === selected);
          });
          EOT
        }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/css610\"}"
          legendFormat = "{{ ifDescr }}"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 82
        type       = "timeseries"
        title      = "CSS610 Port Traffic"
        gridPos    = { h = 8, w = 24, x = 0, y = 117 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bps", custom = { drawStyle = "line", fillOpacity = 10 } }
          overrides = [{ matcher = { id = "byRegexp", options = ".*Tx.*" }, properties = [{ id = "custom.transform", value = "negative-Y" }] }]
        }
        options = { tooltip = { mode = "multi", sort = "desc" }, legend = { displayMode = "table", placement = "bottom", calcs = ["lastNotNull"] } }
        targets = [
          { expr = "rate(ifHCInOctets{job=\"integrations/snmp/css610\"}[$__rate_interval]) * 8", legendFormat = "{{ ifDescr }} Rx", refId = "A" },
          { expr = "rate(ifHCOutOctets{job=\"integrations/snmp/css610\"}[$__rate_interval]) * 8", legendFormat = "{{ ifDescr }} Tx", refId = "B" },
        ]
      },

      # CSS610 Port Detail (drill-down from port map clicks)
      {
        id         = 90
        type       = "timeseries"
        title      = "Port Traffic — $css610_port"
        gridPos    = { h = 8, w = 16, x = 0, y = 125 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults  = { unit = "bps", color = { mode = "palette-classic" } }
          overrides = []
        }
        options = { tooltip = { mode = "multi" } }
        targets = [
          { expr = "rate(ifHCInOctets{job=\"integrations/snmp/css610\",ifDescr=\"$css610_port\"}[$__rate_interval]) * 8", legendFormat = "$css610_port Rx", refId = "A" },
          { expr = "rate(ifHCOutOctets{job=\"integrations/snmp/css610\",ifDescr=\"$css610_port\"}[$__rate_interval]) * 8", legendFormat = "$css610_port Tx", refId = "B" },
        ]
      },
      {
        id         = 91
        type       = "stat"
        title      = "Port Status"
        gridPos    = { h = 4, w = 4, x = 16, y = 125 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            color = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "green", value = 1 },
                { color = "red", value = 2 },
              ]
            }
            mappings = [
              { type = "value", options = { "1" = { text = "Up", color = "green" }, "2" = { text = "Down", color = "red" } } },
            ]
          }
          overrides = []
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] }, colorMode = "background" }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/css610\",ifDescr=\"$css610_port\"}"
          legendFormat = "Status"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 92
        type       = "stat"
        title      = "Link Speed"
        gridPos    = { h = 4, w = 4, x = 20, y = 125 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            unit  = "Mbps"
            color = { mode = "thresholds" }
            thresholds = {
              mode  = "absolute"
              steps = [{ color = "blue", value = null }]
            }
          }
          overrides = []
        }
        targets = [{
          expr         = "ifHighSpeed{job=\"integrations/snmp/css610\",ifDescr=\"$css610_port\"}"
          legendFormat = "Speed"
          refId        = "A"
          instant      = true
        }]
      },
      {
        id         = 93
        type       = "timeseries"
        title      = "Port Status History"
        gridPos    = { h = 4, w = 8, x = 16, y = 129 }
        datasource = { type = "prometheus", uid = data.grafana_data_source.prometheus.uid }
        fieldConfig = {
          defaults = {
            color = { mode = "thresholds" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red", value = null },
                { color = "green", value = 1 },
                { color = "red", value = 2 },
              ]
            }
            mappings = [
              { type = "value", options = { "1" = { text = "Up", color = "green" }, "2" = { text = "Down", color = "red" } } },
            ]
            min = 0
            max = 3
          }
          overrides = []
        }
        options = { tooltip = { mode = "single" } }
        targets = [{
          expr         = "ifOperStatus{job=\"integrations/snmp/css610\",ifDescr=\"$css610_port\"}"
          legendFormat = "Status"
          refId        = "A"
        }]
      },
    ]
  })
}
