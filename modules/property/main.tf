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
# Fetching Akamai group details
#
data "akamai_group" "this" {
  group_name  = var.prop_vars.group_name
  contract_id = var.prop_vars.contract_id
}

#
# Fetching Akamai contract details
#
data "akamai_contract" "this" {
  group_name = var.prop_vars.group_name
}

#
# Templating property rules
#
data "akamai_property_rules_template" "this" {
  template_file = abspath("${path.module}/property-snippets/main.json")

  variables {
    name  = "origin_hostname"
    value = var.prop_vars.origin_hostname
    type  = "string"
  }

  variables {
    name  = "cp_code"
    value = parseint(replace(akamai_cp_code.this.id, "cpc_", ""), 10)
    type  = "number"
  }

  // var_definition_file = abspath("${path.module}/property-snippets/var_defs.json")
  // var_values_file     = abspath("${path.module}/property-snippets/var_vals.json")

}

#
# Configure cp code 
#
resource "akamai_cp_code" "this" {
  product_id  = var.prop_vars.product_id
  contract_id = var.prop_vars.contract_id
  group_id    = data.akamai_group.this.id
  name        = var.prop_vars.cpcode_name
}

#
# Configure edge hostname
#
resource "akamai_edge_hostname" "this" {
  product_id    = var.prop_vars.product_id
  contract_id   = var.prop_vars.contract_id
  group_id      = data.akamai_group.this.id
  ip_behavior   = var.ip_behavior
  edge_hostname = var.prop_vars.edge_hostname
}

locals {
  hostnames = nonsensitive(toset(var.prop_vars.hostnames))
}

#
# Configure property
#
resource "akamai_property" "this" {
  name        = var.prop_vars.hostnames[0]
  product_id  = var.prop_vars.product_id
  contract_id = var.prop_vars.contract_id
  group_id    = data.akamai_group.this.id
  rule_format = var.rule_format

  hostnames {
    cname_from             = var.prop_vars.hostnames[0]
    cname_to               = var.prop_vars.edge_hostname
    cert_provisioning_type = var.cert_provisioning_type
  }

  dynamic "hostnames" {
    for_each = local.hostnames

    content {
      cname_from             = hostnames.value
      cname_to               = var.prop_vars.edge_hostname
      cert_provisioning_type = var.cert_provisioning_type
    }
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
