terraform {
  #
  # AWS S3 backend for remote state
  #
  // backend "s3" {
  //   bucket = "akamai-tf"
  //   key    = "global/s3/terraform.tfstate"
  //   region = "us-west-2"
  //   shared_credentials_file = ".aws/credentials"
  //   profile = "default"
  // }

  #
  # Consul backend for remote state
  #
  backend "consul" {
    address = "consul.anythings.ga"
    scheme  = "https"
    path    = "tfstate"
  }

  required_providers {
    akamai = {
      source = "akamai/akamai"
    }
  }
  required_version = ">= 0.13"
}

#
# Vault setup to fetch input variables
#
provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

#
# Akamai provider setup
#
provider "akamai" {
  edgerc         = var.edgerc
  config_section = "default"
}


#
# Initialize sensitive property variables from Vault
#
data "vault_generic_secret" "property_tfvars" {
  path = "tf/property.tfvars.json"
}

locals {
  prop_vars = jsondecode(data.vault_generic_secret.property_tfvars.data_json)
}

#
# Initialize sensitive appsec variables from Vault
#
data "vault_generic_secret" "appsec_tfvars" {
  path = "tf/appsec.tfvars.json"
}

locals {
  appsec_vars = jsondecode(data.vault_generic_secret.appsec_tfvars.data_json)
}


#
# Property module spins up delivery part of Akamai (Ion Premier)
#
module "property" {
  source                 = "./modules/property"
  ip_behavior            = var.ip_behavior
  rule_format            = var.rule_format
  cert_provisioning_type = var.cert_provisioning_type
  prop_vars              = local.prop_vars
}

#
# Appsec module spins up security part of Akamai (KSD)
#
module "appsec" {
  source       = "./modules/appsec"
  akamai_group = module.property.this_akamai_group
  hostnames    = local.prop_vars.hostnames
  contract_id  = local.prop_vars.contract_id
  appsec_vars  = local.appsec_vars

  depends_on = [module.property]
}

