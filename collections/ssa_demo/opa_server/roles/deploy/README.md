# OPA (Open Policy Agent) Ansible Role

This Ansible role deploys Open Policy Agent (OPA) on Linux systems.

## Requirements

- Ansible 2.9 or higher
- Target system: Linux (tested on Ubuntu 18.04+, CentOS 7+)
- Sudo/root access on target hosts

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `opa_version` | `0.57.0` | OPA version to install |
| `opa_user` | `opa` | System user for OPA service |
| `opa_group` | `opa` | System group for OPA service |
| `opa_home` | `/opt/opa` | OPA home directory |
| `opa_config_dir` | `/etc/opa` | Configuration directory |
| `opa_policies_dir` | `/var/lib/opa` | Data directory |
| `opa_log_dir` | `/var/log/opa` | Log directory |
| `opa_port` | `8181` | Port for OPA server |
| `opa_bind_address` | `0.0.0.0` | Bind address |
| `opa_log_level` | `info` | Log level (debug, info, error) |
| `opa_log_format` | `json` | Log format (json, text) |
| `opa_enable_service` | `true` | Enable systemd service |
| `opa_start_service` | `true` | Start service after installation |

### Configuration

You can customize OPA configuration by setting the `opa_config` variable:

```yaml
opa_config:
  services:
    authz:
      url: http://bundle-server.example.com
  bundles:
    authz:
      service: authz
      resource: "bundles/http/example/authz.tar.gz"
      persist: true
      polling:
        min_delay_seconds: 10
        max_delay_seconds: 20
```

## Dependencies

None.

## Example Playbook

```yaml
---
- hosts: opa-servers
  become: true
  roles:
    - role: opa
      vars:
        opa_version: "0.57.0"
        opa_port: 8181
        opa_log_level: "debug"
        opa_config:
          services:
            bundle_service:
              url: "http://your-bundle-server.com"
          bundles:
            my_bundle:
              service: bundle_service
              resource: "bundles/my-policies.tar.gz"
```

## Testing OPA Installation

After deployment, you can test OPA:

```bash
# Check service status
sudo systemctl status opa

# Test API endpoint
curl http://localhost:8181/v1/data

# Check logs
sudo journalctl -u opa -f
```

## License

MIT

## Author Information

Created for OPA deployment automation.