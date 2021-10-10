output "hostname" {
  value = akamai_property.akamai_property.name
}
output "akamai_group" {
  value = data.akamai_group.group.id
}
output "contract_id" {
  value = data.akamai_group.group.contract_id
}