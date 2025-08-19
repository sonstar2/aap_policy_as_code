# roles/opa-policies/README.md

# OPA Policies Ansible Role

This Ansible role deploys OPA Rego policies using Jinja2 templates, allowing for dynamic configuration through Ansible variables.

## Requirements

- Ansible 2.9 or higher
- OPA already installed and running (use the `opa` role first)
- Target system: Linux

## Role Variables

### Default Variables (defaults/main.yml)

| Variable | Default | Description |
|----------|---------|-------------|
| `opa_policies_dir` | `/var/lib/opa/policies` | Directory for OPA policy files |
| `opa_user` | `opa` | OPA service user |
| `opa_group` | `opa` | OPA service group |
| `opa_service_name` | `opa` | OPA systemd service name |
| `plan_change_start_hour` | `12` | Plan change window start (UTC) |
| `plan_change_end_hour` | `7` | Plan change window end (UTC) |
| `validate_policies` | `true` | Validate policies after deployment |
| `reload_opa_after_update` | `true` | Reload OPA service after updates |

### Policy Configuration

The `policy_files` variable defines which policies to deploy:

```yaml
policy_files:
  - name: "plan-change-window"
    template: "plan-change-window.rego.j2"
    dest_file: "plan-change-window.rego"
```

## Plan Change Window Logic

The plan change window policy prevents job execution during specified hours:

- **Start Hour**: Jobs created at or after this hour (UTC) are blocked
- **End Hour**: Jobs created at or before this hour (UTC) are blocked
- **Example**: Start=12, End=7 blocks jobs from 12:00 UTC to 07:59 UTC next day

### Time Zone Examples

| UTC Hours | EST | PST | Description |
|-----------|-----|-----|-------------|
| 12-07 | 7PM-2AM | 4PM-11PM | Default window |
| 22-06 | 5PM-1AM | 2PM-10PM | Alternative window |

## Dependencies

- OPA must be installed and running
- Requires the `opa` role or equivalent OPA installation

## Example Playbook

```yaml
---
- hosts: opa-servers
  become: true
  roles:
    # First install OPA
    - role: opa
      vars:
        opa_version: "0.57.0"
    
    # Then deploy policies
    - role: opa-policies
      vars:
        plan_change_start_hour: 14  # 2 PM UTC
        plan_change_end_hour: 6     # 6 AM UTC
        validate_policies: true
        policy_files:
          - name: "plan-change-window"
            template: "plan-change-window.rego.j2"
            dest_file: "plan-change-window.rego"
```

## Advanced Configuration

### Multiple Policies

```yaml
policy_files:
  - name: "plan-change-window"
    template: "plan-change-window.rego.j2"
    dest_file: "plan-change-window.rego"
  - name: "custom-policy"
    template: "custom-policy.rego.j2"
    dest_file: "custom-policy.rego"
```

### Custom Time Windows

```yaml
# Block jobs from 10 PM UTC to 8 AM UTC
plan_change_start_hour: 22
plan_change_end_hour: 8
```

## Testing the Policy

After deployment, test the policy:

```bash
# Test with OPA CLI
opa eval -d /var/lib/opa/policies \
  -i '{"created": "2024-01-15T13:30:00Z"}' \
  "data.policies.plan_change_window"

# Expected output during blocked hours:
# {
#   "allowed": false,
#   "violations": ["No job execution allowed during plan change window"]
# }
```

### Sample Input Data

```json
{
  "created": "2024-01-15T13:30:00Z"
}
```

## Policy Output

The policy returns:
- `allowed`: Boolean indicating if job execution is allowed
- `violations`: Array of violation messages
- `plan_change_info`: Additional context about the window

## Troubleshooting

1. **Policy Validation Fails**: Check Rego syntax in templates
2. **OPA Service Won't Reload**: Verify OPA service is running
3. **Policy Not Taking Effect**: Check file permissions and OPA data directory

## License

MIT

## Author Information

Created for OPA policy management and deployment automation.