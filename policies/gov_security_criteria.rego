# Government Sector Auto-Healing EDA Validation Policy
# This policy validates if auto-healing workflows triggered by EDA are appropriate 
# for government environments based on specific compliance and security criteria

package aap.government.autohealing

import rego.v1

# Default deny - fail closed security posture
default allow := false
default violation := {"allowed": false, "message": "Default deny - policy validation required"}

# Government environment classifications
government_environments := {
    "production-classified",
    "production-sensitive", 
    "production-public",
    "staging-classified",
    "staging-sensitive",
    "development-public"
}

# Approved auto-healing playbooks for government use
approved_autohealing_playbooks := {
    "system-restart-approved",
    "service-restart-government",
    "disk-cleanup-secure",
    "memory-cleanup-approved",
    "network-interface-reset-gov",
    "log-rotation-compliant"
}

# Critical systems that require human approval even for approved playbooks
critical_systems := {
    "database-primary",
    "authentication-server",
    "security-gateway",
    "backup-system",
    "monitoring-core"
}

# Business hours for government operations (24h format)
business_hours := {
    "start": 8,
    "end": 17
}

# Allow auto-healing under specific conditions
allow if {
    is_valid_government_environment
    is_approved_autohealing_action
    is_appropriate_severity_level
    meets_compliance_requirements
    not is_maintenance_window
    not requires_human_approval
}

# Validate the target environment is appropriate for government auto-healing
is_valid_government_environment if {
    input.job_template.inventory.name in government_environments
    
    # Additional validation for classified environments
#     input.job_template.inventory.name != "production-classified" if {
#         input.eda_event.severity != "critical"
#     }
# }

# Verify the playbook is approved for government auto-healing
is_approved_autohealing_action if {
    # Check if the job template uses an approved playbook
    some playbook in input.job_template.playbooks
    playbook.name in approved_autohealing_playbooks
    
    # Verify AI-generated flag compliance
    not input.job_template.metadata.ai_generated if {
        input.job_template.inventory.metadata.classification == "classified"
    }
    
    # For sensitive environments, additional restrictions on AI-generated content
    not input.job_template.metadata.ai_generated if {
        input.job_template.inventory.metadata.classification == "sensitive"
        input.eda_event.severity in {"high", "critical"}
    }
}

# Check if the severity level is appropriate for auto-healing
is_appropriate_severity_level if {
    # Auto-healing allowed for medium and high severity in most cases
    input.eda_event.severity in {"medium", "high"}
    
    # Critical events require additional validation
    input.eda_event.severity == "critical" if {
        input.job_template.inventory.name in {
            "production-public", 
            "staging-sensitive", 
            "development-public"
        }
        is_business_hours
    }
}

# Ensure compliance requirements are met
meets_compliance_requirements if {
    # Must have proper authorization
    input.user.organization in government_organizations
    
    # Must have audit logging enabled
    input.job_template.settings.audit_enabled == true
    
    # Must have approval tracking for sensitive operations
    input.job_template.settings.approval_required == false if {
        input.job_template.inventory.classification != "classified"
        not input.eda_event.target_system in critical_systems
    }
    
    # Ensure proper credential usage
    input.job_template.credential.organization != null
    input.job_template.credential.type == "machine"
}

# Check if it's currently business hours (government operations)
is_business_hours if {
    current_hour := to_number(input.current_time.hour)
    current_hour >= business_hours.start
    current_hour <= business_hours.end
    
    # Only weekdays for government operations
    input.current_time.weekday in {1, 2, 3, 4, 5}
}

# Determine if the action requires human approval
requires_human_approval if {
    # Critical systems always require approval
    input.eda_event.target_system in critical_systems
} else if {
    # AI-generated playbooks on classified systems require approval
    input.job_template.metadata.ai_generated == true
    input.job_template.inventory.classification == "classified"
} else if {
    # High-impact changes outside business hours require approval
    input.eda_event.impact_level == "high"
    not is_business_hours
}

# Check if we're in a maintenance window
is_maintenance_window if {
    some window in input.maintenance_schedule.windows
    window.start <= input.current_time.timestamp
    window.end >= input.current_time.timestamp
}

# Government organizations allowed to use auto-healing
government_organizations := {
    "dept-defense",
    "dept-homeland-security", 
    "dept-treasury",
    "dept-justice",
    "general-services-admin"
}

# Violation details for better debugging and audit trails
violation := result if {
    not allow
    
    reasons := array.concat(
        environment_violations,
        array.concat(
            playbook_violations,
            array.concat(
                severity_violations,
                array.concat(
                    compliance_violations,
                    approval_violations
                )
            )
        )
    )
    
    result := {
        "allowed": false,
        "message": "Auto-healing workflow validation failed",
        "violations": reasons,
        "environment": input.job_template.inventory.name,
        "playbook": input.job_template.playbooks[0].name,
        "severity": input.eda_event.severity,
        "target_system": input.eda_event.target_system,
        "timestamp": input.current_time.timestamp,
        "requires_human_approval": requires_human_approval
    }
}

# Environment-related violations
environment_violations := violations if {
    not is_valid_government_environment
    violations := ["Invalid government environment or classification level inappropriate for auto-healing"]
} else := []

# Playbook-related violations  
playbook_violations := violations if {
    not is_approved_autohealing_action
    violations := ["Playbook not approved for government auto-healing or AI-generated content policy violation"]
} else := []

# Severity-related violations
severity_violations := violations if {
    not is_appropriate_severity_level
    violations := ["Severity level inappropriate for automated response or outside business hours"]
} else := []

# Compliance-related violations
compliance_violations := violations if {
    not meets_compliance_requirements
    violations := ["Compliance requirements not met - check authorization, audit logging, and credential policies"]
} else := []

# Approval-related violations
approval_violations := violations if {
    requires_human_approval
    violations := ["Human approval required for this auto-healing action due to system criticality or policy restrictions"]
} else := []

# Success response when policy passes
violation := result if {
    allow
    result := {
        "allowed": true,
        "message": "Auto-healing workflow approved for government environment",
        "environment": input.job_template.inventory.name,
        "playbook": input.job_template.playbooks[0].name,
        "severity": input.eda_event.severity,
        "timestamp": input.current_time.timestamp
    }
}