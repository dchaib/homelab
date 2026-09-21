# Monitoring agent

Installs Alloy on Proxmox VE 9 / Debian Trixie as a native systemd service,
gathers host metrics through `prometheus.exporter.unix`, and forwards them to
Prometheus with remote write. It also installs `smartmontools` and a local
`smartctl_exporter` for disk health and temperature metrics. It forwards the
systemd journal to Loki with the stable labels `instance`, `job`, `unit`, and
`level`.

The exporter is installed from the official Debian `trixie-backports`
repository. APT then manages its updates as part of the normal host updates.

`lm-sensors` is installed for local diagnostics. This role deliberately does
not run `sensors-detect`; it probes hardware and should be run manually only
when required.

## Required configuration

Set `monitoring_agent_prometheus_remote_write_url` to a URL reachable from the
host. It must not use the Docker-only `prometheus` hostname.

Set `monitoring_agent_loki_write_url` to the Loki push URL reachable from the
host. The journal reader starts at most one hour in the past on its first run.

The Alloy UI binds to `127.0.0.1:12345` by default. Override
`monitoring_agent_http_listen_address` only if remote debugging is required.

## SMART devices

By default, `smartctl_exporter` discovers devices automatically. For disks
behind a RAID or HBA controller, set `monitoring_agent_smartctl_exporter_devices`
to the appropriate `smartctl` device arguments, for example:

```yaml
monitoring_agent_smartctl_exporter_devices:
  - /dev/sda
  - /dev/bus/0;megaraid,0
```
