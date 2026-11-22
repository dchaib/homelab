# Network offload workaround

Disable TSO (TCP segmentation offload) and GSO (generic segmentation offload)
on selected physical interfaces to mitigate Intel NIC `Detected Hardware Unit Hang`
errors, following [this workaround](https://first2host.co.uk/blog/how-to-fix-proxmox-detected-hardware-unit-hang/).

Requires a Debian-based host using ifupdown/ifupdown2 for networking.

## Role behavior

`network_offload_workaround_interfaces` lists the affected interfaces and defaults
to `[]`.

The workaround has two parts: disabling TSO/GSO on the live interface and
installing a hook in `/etc/network/if-up.d` to reapply those settings whenever
the interface is activated, including at boot.

- **Empty list:** ensure the hook is absent. Remove it if present; otherwise,
  make no changes. Live settings are neither checked nor changed.
- **Non-empty list:** validate that each interface exists and has a hardware
  device, install `ethtool` if needed, and create or update the hook. Read the
  live settings, disable TSO/GSO if needed, and verify both are `off`.

Networking is not restarted. Removing persistence does not re-enable TSO/GSO;
restoring previous live settings requires a separate manual action.

## Verification

After applying the role and after the next planned reboot, run on the host,
replacing `INTERFACE` with the configured interface name:

```sh
ethtool -k INTERFACE | grep -E '^(tcp|generic)-segmentation-offload:'
```

Both features should be `off`.

Check for new hang messages during representative traffic:

```sh
journalctl -k -b | grep -F 'Detected Hardware Unit Hang'
```
