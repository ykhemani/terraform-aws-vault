variable "region" {
  type        = string
  description = "AWS Region in which to deploy our hashistack instance."
  default     = "us-west-2"
}

variable "vpc_name" {
  type        = string
  description = "Existing VPC in which to deploy our hashistack instance."
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs in which to deploy our hashistack instance."
}

variable "owner_ip" {
  type        = string
  description = "IP address of owner's home or office that will be allowed to access our hashistack instance."
}

variable "owner" {
  type        = string
  description = "Label to identify owner, will be used for tagging resources that are provisioned."
}

variable "domain" {
  type        = string
  description = "Domain in which to provision an DNS A record."
}

variable "hostname" {
  type        = list(string)
  description = "List of DNS A records to provision."
  default     = ["vault"]
}

variable "hashistack_instance_type" {
  type        = string
  description = "Hashistack instance size."
  default     = "t2.large"
}

variable "hashistack_root_size" {
  type        = number
  description = "Hashistack instance root disk size in gigabytes (GB)."
  default     = 40
}
variable "hashistack_intance_count" {
  type        = string
  description = "Number of hashistack instances we want."
  default     = "1"
}

variable "ssh_key_name" {
  type        = string
  description = "Label for SSH key."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key."
}

variable "vault_license" {
  type        = string
  description = "Vault Enterprise license key."
}

# pki stuff
variable "tls_private_key_algorithm" {
  type        = string
  description = "TLS private key algorithm."
  default     = "RSA"
}

variable "common_name" {
  type        = string
  description = "Common name for PKI cert."
}

variable "email_address" {
  type        = string
  description = "Email address for ACME cert request."
}
variable "dns_challenge_provider" {
  type        = string
  description = "DNS challenge provider for ACME cert request."
}

variable "acme_server_url" {
  type        = string
  description = "ACME server."
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "san" {
  type        = list(string)
  description = "Subject alternative names (SAN) for ACME cert request."
}
