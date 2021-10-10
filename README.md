# Akamai Terraform Demo

A simple demo of infrastructure deployment on Akamai. Contains both delivery and security parts. Terraform stated is stored in Consul (AWS S3 optionally), secure storage of input variables in Vault with different key/values pairs. Pieces of code of the infrastructure are taken out into independent Terraform modules.

### property

The module spins up a property per input variables.

### appsec

The module provides control of security products on Akamai.