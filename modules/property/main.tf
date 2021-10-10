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
# Initialize sensitive variables from Vault
#
data "vault_generic_secret" "property_tfvars" {
  path = "tf/property.tfvars.json"
}

#
# Fetching Akamai group details
#
data "akamai_group" "this" {
  group_name  = jsondecode(data.vault_generic_secret.property_tfvars.data_json).group_name
  contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
}

#
# Fetching Akamai contract details
#
data "akamai_contract" "this" {
  group_name = jsondecode(data.vault_generic_secret.property_tfvars.data_json).group_name
}

#
# Templating property rules
#
data "akamai_property_rules_template" "this" {
  template_file = abspath("${path.module}/property-snippets/main.json")

  variables {
    name  = "origin_hostname"
    value = jsondecode(data.vault_generic_secret.property_tfvars.data_json).origin_hostname
    type  = "string"
  }

  variables {
    name  = "cp_code"
    value = parseint(replace(akamai_cp_code.this.id, "cpc_", ""), 10)
    type  = "number"
  }
}

#
# Configure cp code 
#
resource "akamai_cp_code" "this" {
  product_id  = jsondecode(data.vault_generic_secret.property_tfvars.data_json).product_id
  contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
  group_id    = data.akamai_group.this.id
  name        = jsondecode(data.vault_generic_secret.property_tfvars.data_json).cpcode_name
}

#
# Configure edge hostname
#
resource "akamai_edge_hostname" "this" {
  product_id    = jsondecode(data.vault_generic_secret.property_tfvars.data_json).product_id
  contract_id   = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
  group_id      = data.akamai_group.this.id
  ip_behavior   = var.ip_behavior
  edge_hostname = jsondecode(data.vault_generic_secret.property_tfvars.data_json).edge_hostname
}

#
# Configure property
#
resource "akamai_property" "this" {
  name        = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostnames[0]
  product_id  = jsondecode(data.vault_generic_secret.property_tfvars.data_json).product_id
  contract_id = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
  group_id    = data.akamai_group.this.id
  rule_format = var.rule_format

  hostnames {
    cname_from             = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostnames[0]
    cname_to               = jsondecode(data.vault_generic_secret.property_tfvars.data_json).edge_hostname
    cert_provisioning_type = var.cert_provisioning_type
  }

  hostnames {
    cname_from             = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostnames[1]
    cname_to               = jsondecode(data.vault_generic_secret.property_tfvars.data_json).edge_hostname
    cert_provisioning_type = var.cert_provisioning_type
  }

  hostnames {
    cname_from             = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostnames[2]
    cname_to               = jsondecode(data.vault_generic_secret.property_tfvars.data_json).edge_hostname
    cert_provisioning_type = var.cert_provisioning_type
  }

  rules = data.akamai_property_rules_template.this.json
}

#
# Activate property
#
// resource "akamai_property_activation" "activation" {
//   property_id = akamai_property.this.id
//   contact = [ var.email ]
//   version = akamai_property.this.latest_version
//   network = upper(var.akamai_network)
// }
