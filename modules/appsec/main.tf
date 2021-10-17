#
# Define Akamai provider source
#
terraform {
  required_providers {
    akamai = {
      source = "akamai/akamai"
    }
  }
  required_version = ">= 0.13"
}

#
# Example of wrapping ciphertext of variables with decrypting in Vault
#
// data "vault_transit_decrypt" "appsec_tfvars" {
//   backend     = "transit"
//   key         = "tf-transit"
//   ciphertext  = "vault:v1:6QeZ+MMKPq9cLszrehW2X+R7kDy6mz3G6qEFHodpGxY6T/adoDvwuOPIEA6jxI2QWq4sZAC3yNXECGwR7nypQ8w8KCWAE7cHsPA8FDqdgQtXPG45OOsHt+h9f66JQ/cNWUnp1Mrad1VH8C0SHo8ZO9rVmANTD3XQuISl+8DBDHzCnnUQKLori2gkzyfvwzR9FgQH6hDiZPhB/Qntme7NNz6GF5my7G+Ph0NctSmi+Ps/meABJjMTSoCN3k79Ru8nFLPUY3Pc9OnI+VZJ6DPRSfFleQkJvY3Gtr/r1HYjXs+V0gwyajuabvc35WPzQ0GxGG9TjfxfrirOtT5Ij/S/+aflcVrQgiZb9PMIFAASDPB56eM0Oa3x4aQ9ji4hmBGgVxhYQ9vg+MVX6QhjRHIQ4dbvtbY2QoEtDzjpnICRWSONTcJZbNHFCmNhAQens4oRBjq5tItv0PoRy25cH8Kibz43uSjcNuKiOZYHXHKIj6GoNKBmGFKiKmbdvdN4ZEcMocAV6mmzuFdi/tP3x8mi7d/7pJrlxdR5okjpXsDUbwwB8I0isTUOSGDbB/x+EEydRxKJApSfnnlp0NWozLne4igHosfw6EVRGxH/v8Vi4UQWKljY7E8OfQ/jB1/TMQq8+0XsqW/wJ01DWkpn/C3Elas7Jv1RtUe5KYpOpegYIJ10a/b193lpJGlEHXve0n+oEOAq+317mmvIihNYepiTr02r8jJlpotYuvdsWUsoy0/PyrKIJy0He96Dc5caHYTvFrM3Vvb8l7PbIsUW1/TkSUQgmd1A9ghZetOPqdtltszXyLnShIx3UgcHu0iy6NmEBrIxiyhAunAkS8nAW5NRMYWaIE9pVPIhjgK/Iu4YRLKpCNosNnwziKg6U+ZSJQOKnGXAUUTGckpvQ8+OiyzPS4WRFXMGbwThrP5ucBVsbdcVwXQkZzk1X7iMwOvoDih3F/IdKdwr9hI129EnTEoOaYXcLEp+3Lzw9wDOAsHGSrlhmPY/9k5czfZuehx++eA0a9/KvHvu77as9OvamXhCM9QlVYM+oilXKrF0OLH3nGBIBsE/zITzCZVJ0h6QioP5PEfqVnQ17iIUo4y9a0v0dEF0Km8KRieLgEFqwQycOHoQzOqGH7MzuMFj403jPaFkJkBYSAtiSSppqxsJrN5VuZ/PHd2u74/9+fS/ZixbOCzSWqzBQq2lRREOAEGrm4UofzCJs20zh/yhPWOH17zuJnp9wxDh9bblLWI65vJuksuokR+ikCpXnCJAr4hSR40bXPyfj8aZVG9O5adh9mifp68HqJOwUFoFhX0FeDFgnsFKgtPZjbakwY5EVVs6H71BcVbajItabPJdrCZcbc3I3qCafHrOA1cQLnoJQrGbE7JN11YvkGZJjyHQiFMNZFqjL1PNl6rVscWlbVNl5n+l4hdAlGmr7/qDt7bTIjqkY+hA1iBmtwqQ6CM3lRMIrm6PiKO9IkX2j9o6HKOTIPH5A+L6kVFOA57gfCWlFPqJwH3KbChSt9gxaLf/AswgChA/lc82WoYQ+TGSH4iRVDUGdIP2wqCrPj6BPV12bpQ6iFKMnd2HcnSQOr3SL9vr7wL0jX/Pae4MODTHmqmaZTP9AA5mosWqLClThBw="
// }

#
# Security configuration
#
resource "akamai_appsec_configuration" "this" {
  contract_id = replace(var.contract_id, "ctr_", "")
  group_id    = replace(var.akamai_group, "grp_", "")
  name        = var.appsec_vars.configuration_name
  description = var.appsec_vars.configuration_description
  host_names  = var.hostnames
}

#
# Security policy
#
resource "akamai_appsec_security_policy" "this" {
  config_id              = akamai_appsec_configuration.this.config_id
  security_policy_name   = var.appsec_vars.policy_name
  security_policy_prefix = var.appsec_vars.policy_prefix
}

#
# Pragma debug header settings from file
#
resource "akamai_appsec_advanced_settings_pragma_header" "this" {
  config_id          = akamai_appsec_configuration.this.config_id
  security_policy_id = akamai_appsec_security_policy.this.security_policy_id
  pragma_header      = file("${path.module}/appsec-snippets/pragma_header.json")
}


#
# Match Target for security configuration
#
resource "akamai_appsec_match_target" "this" {
  config_id = akamai_appsec_configuration.this.config_id
  match_target = templatefile("${path.module}/appsec-snippets/match_targets.tpl", {
    config_id           = akamai_appsec_configuration.this.config_id,
    hostnames           = var.hostnames,
    policy_id           = akamai_appsec_security_policy.this.security_policy_id
    securitybypass_list = akamai_networklist_network_list.security_bypasslist.id
    }
  )
}

#
# IP Blocklist Network List
#
resource "akamai_networklist_network_list" "ip_blocklist" {
  name        = "IPBLOCKLIST"
  type        = "IP"
  description = "IPBLOCKLIST"
  list        = var.appsec_vars.ipblock_list
  mode        = "REPLACE"
}

#
# IP Blocklist Exceptions Network List
#
resource "akamai_networklist_network_list" "ip_blocklist_exceptions" {
  name        = "IPBLOCKLISTEXCEPTIONS"
  type        = "IP"
  description = "IPBLOCKLISTEXCEPTIONS"
  list        = var.appsec_vars.ipblock_list_exceptions
  mode        = "REPLACE"
}

#
# GEO Blocklist Network List
#
resource "akamai_networklist_network_list" "geo_blocklist" {
  name        = "GEOBLOCKLIST"
  type        = "GEO"
  description = "GEOBLOCKLIST"
  list        = var.appsec_vars.geoblock_list
  mode        = "REPLACE"
}

#
# Security Bypass Network List
#
resource "akamai_networklist_network_list" "security_bypasslist" {
  name        = "SECURITYBYPASSLIST"
  type        = "IP"
  description = "SECURITYBYPASSLIST"
  list        = var.appsec_vars.securitybypass_list
  mode        = "REPLACE"
}

#
# IP/GEO Firewall
#
resource "akamai_appsec_ip_geo" "ip_geo_block" {
  config_id                  = akamai_appsec_configuration.this.config_id
  security_policy_id         = akamai_appsec_security_policy.this.security_policy_id
  mode                       = "block"
  ip_network_lists           = [akamai_networklist_network_list.ip_blocklist.id]
  geo_network_lists          = [akamai_networklist_network_list.geo_blocklist.id]
  exception_ip_network_lists = [akamai_networklist_network_list.ip_blocklist_exceptions.id]
}

#
# Page View Requests Rate Control
#
resource "akamai_appsec_rate_policy" "page_view_requests" {
  config_id   = akamai_appsec_configuration.this.config_id
  rate_policy = file("${path.module}/appsec-snippets/rate-policies/page_view_requests.json")
}

#
# Page View Requests Rate Control Action
#
resource "akamai_appsec_rate_policy_action" "page_view_requests_action" {
  config_id          = akamai_appsec_configuration.this.config_id
  security_policy_id = akamai_appsec_security_policy.this.security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.page_view_requests.rate_policy_id
  ipv4_action        = var.appsec_vars.page_view_requests_action
  ipv6_action        = var.appsec_vars.page_view_requests_action
}

#
# Origin Error Rate Control
#
resource "akamai_appsec_rate_policy" "origin_error" {
  config_id   = akamai_appsec_configuration.this.config_id
  rate_policy = file("${path.module}/appsec-snippets/rate-policies/origin_error.json")
}

#
# Origin Error Rate Control Action
#
resource "akamai_appsec_rate_policy_action" "origin_error_action" {
  config_id          = akamai_appsec_configuration.this.config_id
  security_policy_id = akamai_appsec_security_policy.this.security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.origin_error.rate_policy_id
  ipv4_action        = var.appsec_vars.origin_error_action
  ipv6_action        = var.appsec_vars.origin_error_action
}

#
# POST Requests Rate Control
#
resource "akamai_appsec_rate_policy" "post_requests" {
  config_id   = akamai_appsec_configuration.this.config_id
  rate_policy = file("${path.module}/appsec-snippets/rate-policies/post_requests.json")
}

#
# POST Requests Rate Control Action
#
resource "akamai_appsec_rate_policy_action" "post_requests_action" {
  config_id          = akamai_appsec_configuration.this.config_id
  security_policy_id = akamai_appsec_security_policy.this.security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.post_requests.rate_policy_id
  ipv4_action        = var.appsec_vars.post_requests_action
  ipv6_action        = var.appsec_vars.post_requests_action
}

#
# Slow POST
#
resource "akamai_appsec_slow_post" "slow_post" {
  config_id                  = akamai_appsec_configuration.this.config_id
  security_policy_id         = akamai_appsec_security_policy.this.security_policy_id
  slow_rate_action           = var.appsec_vars.slow_post_protection_action
  slow_rate_threshold_rate   = 10
  slow_rate_threshold_period = 60
}

#
# WAF Web Attack Tool Attack Group
#
resource "akamai_appsec_attack_group" "web_attack_tool" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "TOOL"
  attack_group_action = var.appsec_vars.web_attack_tool_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/web_attack_tool_exception.json")
}

#
# WAF Web Protocol Attack Attack Group
#
resource "akamai_appsec_attack_group" "web_protocol_attack" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "PROTOCOL"
  attack_group_action = var.appsec_vars.web_protocol_attack_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/web_protocol_attack_exception.json")
}

#
# WAF SQL Injection Attack Group
#
resource "akamai_appsec_attack_group" "sql_injection" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "SQL"
  attack_group_action = var.appsec_vars.sql_injection_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/sql_injection_exception.json")
}

#
# WAF Cross Site Scripting Attack Group
#
resource "akamai_appsec_attack_group" "cross_site_scripting" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "XSS"
  attack_group_action = var.appsec_vars.cross_site_scripting_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/cross_site_scripting_exception.json")
}

#
# WAF Local File Inclusion Attack Group
#
resource "akamai_appsec_attack_group" "local_file_inclusion" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "LFI"
  attack_group_action = var.appsec_vars.local_file_inclusion_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/local_file_inclusion_exception.json")
}

#
# WAF Remote File Inclusion Attack Group
#
resource "akamai_appsec_attack_group" "remote_file_inclusion" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "RFI"
  attack_group_action = var.appsec_vars.remote_file_inclusion_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/remote_file_inclusion_exception.json")
}

#
# WAF Command Injection Attack Group
#
resource "akamai_appsec_attack_group" "command_injection" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "CMDI"
  attack_group_action = var.appsec_vars.command_injection_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/command_injection_exception.json")
}

#
# WAF Web Platform Attack Attack Group
#
resource "akamai_appsec_attack_group" "web_platform_attack" {
  config_id           = akamai_appsec_configuration.this.config_id
  security_policy_id  = akamai_appsec_security_policy.this.security_policy_id
  attack_group        = "PLATFORM"
  attack_group_action = var.appsec_vars.web_platform_attack_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/web_platform_attack_exception.json")
}

#
# Security Configuration Activation
#
// resource "akamai_appsec_activations" "activation" {
//   config_id = akamai_appsec_configuration.this.config_id
//   network = upper(var.akamai_network)
//   notes  = var.appsec_vars.activation_notes
//   notification_emails = [ var.email ]

//   depends_on = [ 
//     akamai_appsec_configuration.akamai_appsec, 
//     akamai_appsec_security_policy.security_policy, 
//     akamai_appsec_advanced_settings_pragma_header.this,
//     akamai_appsec_match_target.this, 
//     akamai_appsec_ip_geo.ip_geo_block,
//     akamai_appsec_rate_policy.page_view_requests,
//     akamai_appsec_rate_policy.origin_error,
//     akamai_appsec_rate_policy.post_requests,
//     akamai_appsec_slow_post.slow_post
//     ]
// }