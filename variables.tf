variable "edgerc" {
    type = string
    default = ".edgerc"
}
variable "ip_behavior" {
    type = string
    default = "IPV6_COMPLIANCE"
}
variable "rule_format" {
    type = string
    default = "v2020-11-02"
}
variable "cert_provisioning_type" {
    type = string
    default = "CPS_MANAGED"
}
variable "vault_token" {
    type = string
}
variable "vault_address" {
    type = string
}