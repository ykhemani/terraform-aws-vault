################################################################################
# acme tls cert
provider "acme" {
  server_url = var.acme_server_url
}

resource "tls_private_key" "private_key" {
  algorithm = var.tls_private_key_algorithm
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email_address
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = var.common_name
  subject_alternative_names = var.san

  dns_challenge {
    provider = var.dns_challenge_provider
  }
}
