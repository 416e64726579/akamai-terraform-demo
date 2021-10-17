variable "hostnames" {
  type        = list(string)
  description = "The hostnames associated with the security configuration."
}
variable "akamai_group" {
  type        = string
  description = "Akamai Group Name"
}
variable "contract_id" {
  type        = string
  description = "Akamai Contract ID"
}
variable "appsec_vars" {
  type        = any
  description = "Object of security variables"
}