variable "edgerc" {
  type        = string
  description = "Akamai authentication file path"

}
variable "ip_behavior" {
  type        = string
  description = "IPV4+IPV6 enabled with IPV6_COMPLIANCE FLAG"

}
variable "rule_format" {
  type        = string
  description = "Property rule format"

}
variable "cert_provisioning_type" {
  type        = string
  description = "DEFAULT = Secure By Default, CPS_MANAGED = CPS managed certificates"

}