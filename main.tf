terraform {

  // backend "s3" {
  //   bucket = "akamai-tf"
  //   key    = "global/s3/terraform.tfstate"
  //   region = "us-west-2"
  //   shared_credentials_file = ".aws/credentials"
  //   profile = "default"
  // }

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

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

provider "akamai" {
  edgerc         = var.edgerc
  config_section = "default"
}

module "property" {
  source                 = "./modules/property"
  edgerc                 = var.edgerc
  ip_behavior            = var.ip_behavior
  rule_format            = var.rule_format
  cert_provisioning_type = var.cert_provisioning_type
}

module "appsec" {
  source       = "./modules/appsec"
  hostname     = module.property.hostname
  akamai_group = module.property.akamai_group
  contract_id  = module.property.contract_id
  depends_on   = [module.property]
}

