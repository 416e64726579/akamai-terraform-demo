output "this_property_hostnames" {
  value = jsondecode(data.vault_generic_secret.property_tfvars.data_json).hostnames
}
output "this_akamai_group" {
  value = data.akamai_group.this.id
}
output "this_contract_id" {
  value = jsondecode(data.vault_generic_secret.property_tfvars.data_json).contract_id
}