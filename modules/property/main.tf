data "vault_generic_secret" "property_tfvars" {
  path = "tf/property.tfvars.json"
}

terraform {
  required_providers {
    akamai = { 
      source = "akamai/akamai" 
    }
  }
  required_version = ">= 0.13"
}

data "akamai_group" "group" {
 group_name = jsondecode(data.vault_generic_secret.property_tfvars.data_json).group_name
 contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
}

data "akamai_contract" "contract" {
  group_name = jsondecode(data.vault_generic_secret.property_tfvars.data_json).group_name
}

data "akamai_property_rules_template" "rules" {
  template_file = abspath("${path.module}/property-snippets/main.json")

  variables {
    name = "origin_hostname"
    value = jsondecode(data.vault_generic_secret.property_tfvars.data_json).origin_hostname
    type = "string"
  }

  variables {
    name = "cp_code"
    value = parseint(replace(akamai_cp_code.cp_code.id, "cpc_", ""), 10)
    type = "number"
  }
}

resource "akamai_cp_code" "cp_code" {
  product_id  = jsondecode(data.vault_generic_secret.property_tfvars.data_json).product_id
  contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
  group_id = data.akamai_group.group.id
  name = jsondecode(data.vault_generic_secret.property_tfvars.data_json).cpcode_name
}

resource "akamai_edge_hostname" "edge_hostname" {
  product_id  = jsondecode(data.vault_generic_secret.property_tfvars.data_json).product_id
  contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
  group_id = data.akamai_group.group.id
  ip_behavior = var.ip_behavior
  edge_hostname = jsondecode(data.vault_generic_secret.property_tfvars.data_json).edge_hostname 
}

resource "akamai_property" "akamai_property" {
  name = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostname
  product_id  = jsondecode(data.vault_generic_secret.property_tfvars.data_json).product_id
  contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
  group_id = data.akamai_group.group.id
  rule_format = var.rule_format

  hostnames {
    cname_from = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostname
    cname_to = jsondecode(data.vault_generic_secret.property_tfvars.data_json).edge_hostname
    cert_provisioning_type = var.cert_provisioning_type
  }
 
  rules = data.akamai_property_rules_template.rules.json
}

// resource "akamai_property_activation" "activation" {
//   property_id = akamai_property.akamai_property.id
//   contact = [ var.email ]
//   version = akamai_property.akamai_property.latest_version
//   network = upper(var.akamai_network)
// }
