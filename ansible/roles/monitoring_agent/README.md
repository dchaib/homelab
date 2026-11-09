# Monitoring agent

Installs Alloy on the physical Proxmox VE 9 / Debian Trixie hosts as a native
systemd service. It gathers host metrics through `prometheus.exporter.unix`
and forwards them to Prometheus with remote write. It forwards the systemd
journal to Loki with the stable labels `instance`, `job`, `unit`, and `level`.
The separate `hardware_monitoring` role manages `smartmontools` and `smartd`.

On `pve-01`, this role also installs a local `smartctl_exporter` from the official
Debian `trixie-backports` repository. APT manages its normal updates. On `nas-01`,
`monitoring_agent_smartctl_exporter_enabled: false` skips its installation,
configuration, start and scrape to preserve SATA disk standby. This switch does
not uninstall an exporter installed outside this role or by an earlier run.

The role does not install `lm-sensors`, run `sensors-detect`, or load sensor
drivers. Native thermal metrics use the kernel interfaces already available.

## Required configuration

Set `monitoring_agent_prometheus_remote_write_url` to a URL reachable from the
host. It must not use the Docker-only `prometheus` hostname.

Set `monitoring_agent_loki_write_url` to the Loki push URL reachable from the
host. The journal reader starts at most one hour in the past on its first run.

The Alloy UI binds to `127.0.0.1:12345` by default. Override
`monitoring_agent_http_listen_address` only if remote debugging is required.

## Collectors

The default unix collectors remain enabled, including `hwmon`, `thermal_zone`
and `zfs`. A nonempty `monitoring_agent_systemd_units` list additionally enables
`systemd`, restricted to those exact unit names; it does not replace the defaults.
An empty list leaves the systemd collector disabled.

### Proxmox systemd services

On `pve-01`, `monitoring_agent_systemd_units` selects eight permanent services,
verified as `active/running` on 2026-11-09:

| Unit | Purpose |
| --- | --- |
| `alloy.service` | Collect and forward host metrics and the journal |
| `smartmontools.service` | Local SMART monitoring through smartd |
| `smartctl_exporter.service` | Existing NVMe SMART metrics |
| `pve-cluster.service` | pmxcfs configuration filesystem, required even without a cluster |
| `pvedaemon.service` | Privileged Proxmox API and task workers |
| `pveproxy.service` | HTTPS API and web interface |
| `pvestatd.service` | Guest and storage status collection |
| `qmeventd.service` | QEMU shutdown events and guest cleanup for the two configured VMs |

`pve-guests.service` is deliberately excluded: it is a boot/shutdown `oneshot`
with `RemainAfterExit=yes`, normally `active/exited`, not a running daemon or
a measure of guest availability. Its executions remain visible in the journal.

Corosync is inactive without `corosync.conf`; HA resources, LXC guests, Proxmox
firewall configuration and scheduled Proxmox jobs are absent on this standalone
host. Their services, including `pvescheduler`, are not selected merely because
they are installed or running. SPICE and daily update timers/oneshots are also
outside this short list. Revisit the list if those features are configured.

After deployment, inspect `node_systemd_unit_state{instance="pve-01"}` for the
eight units. The `state="active"` series should be 1 during normal operation;
systemd state alone does not guarantee API or guest health. Existing unix
collectors, the SMART scrape and journal forwarding remain unchanged. No alert
rules are added.

### NAS hardware sensors

`monitoring_agent_hwmon_chip_exclude` optionally excludes chips **before**
reading their sensor values. It matches the device-derived `chip` identifier,
not the readable `chip_name`. The NAS excludes both the SCSI identifiers used
by `drivetemp` and the `drivetemp` name fallback. CPU, motherboard and NVMe
sensors remain eligible. No disk-temperature experiment is performed.

## SMART devices

By default, `smartctl_exporter` discovers devices automatically. For disks
behind a RAID or HBA controller, set `monitoring_agent_smartctl_exporter_devices`
to the appropriate `smartctl` device arguments, for example:

```yaml
monitoring_agent_smartctl_exporter_devices:
  - /dev/sda
  - /dev/bus/0;megaraid,0
```
