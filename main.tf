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
# Property module spins up delivery part of Akamai (Ion Premier)
#
module "property" {
  source                 = "./modules/property"
  edgerc                 = var.edgerc
  ip_behavior            = var.ip_behavior
  rule_format            = var.rule_format
  cert_provisioning_type = var.cert_provisioning_type
}

#
# Appsec module spins up security part of Akamai (KSD)
#
module "appsec" {
  source       = "./modules/appsec"
  hostnames    = module.property.this_property_hostnames
  akamai_group = module.property.this_akamai_group
  contract_id  = module.property.this_contract_id
  depends_on   = [module.property]
}

