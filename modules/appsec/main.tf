data "vault_generic_secret" "appsec_tfvars" {
  path = "tf/appsec.tfvars.json"
}

// data "vault_transit_decrypt" "appsec_tfvars" {
//   backend     = "transit"
//   key         = "tf-transit"
//   ciphertext  = "vault:v1:6QeZ+MMKPq9cLszrehW2X+R7kDy6mz3G6qEFHodpGxY6T/adoDvwuOPIEA6jxI2QWq4sZAC3yNXECGwR7nypQ8w8KCWAE7cHsPA8FDqdgQtXPG45OOsHt+h9f66JQ/cNWUnp1Mrad1VH8C0SHo8ZO9rVmANTD3XQuISl+8DBDHzCnnUQKLori2gkzyfvwzR9FgQH6hDiZPhB/Qntme7NNz6GF5my7G+Ph0NctSmi+Ps/meABJjMTSoCN3k79Ru8nFLPUY3Pc9OnI+VZJ6DPRSfFleQkJvY3Gtr/r1HYjXs+V0gwyajuabvc35WPzQ0GxGG9TjfxfrirOtT5Ij/S/+aflcVrQgiZb9PMIFAASDPB56eM0Oa3x4aQ9ji4hmBGgVxhYQ9vg+MVX6QhjRHIQ4dbvtbY2QoEtDzjpnICRWSONTcJZbNHFCmNhAQens4oRBjq5tItv0PoRy25cH8Kibz43uSjcNuKiOZYHXHKIj6GoNKBmGFKiKmbdvdN4ZEcMocAV6mmzuFdi/tP3x8mi7d/7pJrlxdR5okjpXsDUbwwB8I0isTUOSGDbB/x+EEydRxKJApSfnnlp0NWozLne4igHosfw6EVRGxH/v8Vi4UQWKljY7E8OfQ/jB1/TMQq8+0XsqW/wJ01DWkpn/C3Elas7Jv1RtUe5KYpOpegYIJ10a/b193lpJGlEHXve0n+oEOAq+317mmvIihNYepiTr02r8jJlpotYuvdsWUsoy0/PyrKIJy0He96Dc5caHYTvFrM3Vvb8l7PbIsUW1/TkSUQgmd1A9ghZetOPqdtltszXyLnShIx3UgcHu0iy6NmEBrIxiyhAunAkS8nAW5NRMYWaIE9pVPIhjgK/Iu4YRLKpCNosNnwziKg6U+ZSJQOKnGXAUUTGckpvQ8+OiyzPS4WRFXMGbwThrP5ucBVsbdcVwXQkZzk1X7iMwOvoDih3F/IdKdwr9hI129EnTEoOaYXcLEp+3Lzw9wDOAsHGSrlhmPY/9k5czfZuehx++eA0a9/KvHvu77as9OvamXhCM9QlVYM+oilXKrF0OLH3nGBIBsE/zITzCZVJ0h6QioP5PEfqVnQ17iIUo4y9a0v0dEF0Km8KRieLgEFqwQycOHoQzOqGH7MzuMFj403jPaFkJkBYSAtiSSppqxsJrN5VuZ/PHd2u74/9+fS/ZixbOCzSWqzBQq2lRREOAEGrm4UofzCJs20zh/yhPWOH17zuJnp9wxDh9bblLWI65vJuksuokR+ikCpXnCJAr4hSR40bXPyfj8aZVG9O5adh9mifp68HqJOwUFoFhX0FeDFgnsFKgtPZjbakwY5EVVs6H71BcVbajItabPJdrCZcbc3I3qCafHrOA1cQLnoJQrGbE7JN11YvkGZJjyHQiFMNZFqjL1PNl6rVscWlbVNl5n+l4hdAlGmr7/qDt7bTIjqkY+hA1iBmtwqQ6CM3lRMIrm6PiKO9IkX2j9o6HKOTIPH5A+L6kVFOA57gfCWlFPqJwH3KbChSt9gxaLf/AswgChA/lc82WoYQ+TGSH4iRVDUGdIP2wqCrPj6BPV12bpQ6iFKMnd2HcnSQOr3SL9vr7wL0jX/Pae4MODTHmqmaZTP9AA5mosWqLClThBw="
// }

terraform {
  required_providers {
    akamai = {
      source = "akamai/akamai"
    }
  }
  required_version = ">= 0.13"
}

resource "akamai_appsec_configuration" "akamai_appsec" {
  contract_id = replace(var.contract_id, "ctr_", "")
  group_id    = replace(var.akamai_group, "grp_", "")
  name        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).configuration_name
  description = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).configuration_description
  host_names  = [var.hostname]
}

resource "akamai_appsec_security_policy" "security_policy" {
  config_id              = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_name   = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).policy_name
  security_policy_prefix = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).policy_prefix
}

resource "akamai_appsec_advanced_settings_pragma_header" "pragma_header" {
  config_id          = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id = akamai_appsec_security_policy.security_policy.security_policy_id
  pragma_header      = file("${path.module}/appsec-snippets/pragma_header.json")
}

resource "akamai_appsec_match_target" "match_target" {
  config_id = akamai_appsec_configuration.akamai_appsec.config_id
  match_target = templatefile("${path.module}/appsec-snippets/match_targets.json", {
    config_id           = akamai_appsec_configuration.akamai_appsec.config_id,
    hostname            = var.hostname,
    policy_id           = akamai_appsec_security_policy.security_policy.security_policy_id
    securitybypass_list = akamai_networklist_network_list.SECURITYBYPASSLIST.id
    }
  )
}

resource "akamai_networklist_network_list" "IPBLOCKLIST" {
  name        = "IPBLOCKLIST"
  type        = "IP"
  description = "IPBLOCKLIST"
  list        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ipblock_list
  mode        = "REPLACE"
}

resource "akamai_networklist_network_list" "IPBLOCKLISTEXCEPTIONS" {
  name        = "IPBLOCKLISTEXCEPTIONS"
  type        = "IP"
  description = "IPBLOCKLISTEXCEPTIONS"
  list        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ipblock_list_exceptions
  mode        = "REPLACE"
}

resource "akamai_networklist_network_list" "GEOBLOCKLIST" {
  name        = "GEOBLOCKLIST"
  type        = "GEO"
  description = "GEOBLOCKLIST"
  list        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).geoblock_list
  mode        = "REPLACE"
}

resource "akamai_networklist_network_list" "SECURITYBYPASSLIST" {
  name        = "SECURITYBYPASSLIST"
  type        = "IP"
  description = "SECURITYBYPASSLIST"
  list        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).securitybypass_list
  mode        = "REPLACE"
}

resource "akamai_appsec_ip_geo" "ip_geo_block" {
  config_id                  = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id         = akamai_appsec_security_policy.security_policy.security_policy_id
  mode                       = "block"
  ip_network_lists           = [akamai_networklist_network_list.IPBLOCKLIST.id]
  geo_network_lists          = [akamai_networklist_network_list.GEOBLOCKLIST.id]
  exception_ip_network_lists = [akamai_networklist_network_list.IPBLOCKLISTEXCEPTIONS.id]
}

resource "akamai_appsec_rate_policy" "rate_policy_page_view_requests" {
  config_id   = akamai_appsec_configuration.akamai_appsec.config_id
  rate_policy = file("${path.module}/appsec-snippets/rate-policies/rate_policy_page_view_requests.json")
}

resource "akamai_appsec_rate_policy_action" "appsec_rate_policy_page_view_requests_action" {
  config_id          = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id = akamai_appsec_security_policy.security_policy.security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.rate_policy_page_view_requests.rate_policy_id
  ipv4_action        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ratepolicy_page_view_requests_action
  ipv6_action        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ratepolicy_page_view_requests_action
}

resource "akamai_appsec_rate_policy" "rate_policy_origin_error" {
  config_id   = akamai_appsec_configuration.akamai_appsec.config_id
  rate_policy = file("${path.module}/appsec-snippets/rate-policies/rate_policy_origin_error.json")
}

resource "akamai_appsec_rate_policy_action" "appsec_rate_policy_origin_error_action" {
  config_id          = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id = akamai_appsec_security_policy.security_policy.security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.rate_policy_origin_error.rate_policy_id
  ipv4_action        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ratepolicy_origin_error_action
  ipv6_action        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ratepolicy_origin_error_action
}

resource "akamai_appsec_rate_policy" "rate_policy_post_requests" {
  config_id   = akamai_appsec_configuration.akamai_appsec.config_id
  rate_policy = file("${path.module}/appsec-snippets/rate-policies/rate_policy_post_requests.json")
}

resource "akamai_appsec_rate_policy_action" "appsec_rate_policy_post_requests_action" {
  config_id          = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id = akamai_appsec_security_policy.security_policy.security_policy_id
  rate_policy_id     = akamai_appsec_rate_policy.rate_policy_post_requests.rate_policy_id
  ipv4_action        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ratepolicy_post_requests_action
  ipv6_action        = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).ratepolicy_post_requests_action
}

resource "akamai_appsec_slow_post" "slow_post" {
  config_id                  = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id         = akamai_appsec_security_policy.security_policy.security_policy_id
  slow_rate_action           = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).slow_post_protection_action
  slow_rate_threshold_rate   = 10
  slow_rate_threshold_period = 60
}

resource "akamai_appsec_attack_group" "attack_group_web_attack_tool" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "TOOL"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_web_attack_tool_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_web_attack_tool_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_web_protocol_attack" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "PROTOCOL"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_web_protocol_attack_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_web_protocol_attack_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_sql_injection" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "SQL"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_sql_injection_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_sql_injection_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_cross_site_scripting" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "XSS"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_cross_site_scripting_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_cross_site_scripting_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_local_file_inclusion" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "LFI"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_local_file_inclusion_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_local_file_inclusion_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_remote_file_inclusion" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "RFI"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_remote_file_inclusion_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_remote_file_inclusion_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_command_injection" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "CMDI"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_command_injection_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_command_injection_exception.json")
}

resource "akamai_appsec_attack_group" "attack_group_web_platform_attack" {
  config_id           = akamai_appsec_configuration.akamai_appsec.config_id
  security_policy_id  = akamai_appsec_security_policy.security_policy.security_policy_id
  attack_group        = "PLATFORM"
  attack_group_action = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).attack_group_web_platform_attack_action
  condition_exception = file("${path.module}/appsec-snippets/attack-groups/attack_group_web_platform_attack_exception.json")
}

// resource "akamai_appsec_activations" "activation" {
//   config_id = akamai_appsec_configuration.akamai_appsec.config_id
//   network = upper(var.akamai_network)
//   notes  = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json).activation_notes
//   notification_emails = [ var.email ]

//   depends_on = [ 
//     akamai_appsec_configuration.akamai_appsec, 
//     akamai_appsec_security_policy.security_policy, 
//     akamai_appsec_advanced_settings_pragma_header.pragma_header,
//     akamai_appsec_match_target.match_target, 
//     akamai_appsec_ip_geo.ip_geo_block,
//     akamai_appsec_rate_policy.rate_policy_page_view_requests,
//     akamai_appsec_rate_policy.rate_policy_origin_error,
//     akamai_appsec_rate_policy.rate_policy_post_requests,
//     akamai_appsec_slow_post.slow_post
//     ]
// }