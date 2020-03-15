################################################################################
# use existing ssh key as defined by ssh_public_key variable
resource "aws_key_pair" "ssh" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
  tags = {
    Owner = var.owner
  }
}

################################################################################
# let's find the latest hashistack image for this owner
data "aws_ami" "hashistack" {
  most_recent = true

  filter {
    name = "name"
    values = ["hashistack-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:Owner"
    values = [var.owner]
  }

  owners = ["self"]
}

################################################################################
# let's define our user data
data "template_file" "user_data" {
  template = file("userdata.tpl")

  vars = {
    kms_key         = aws_kms_key.vault.id
    aws_region      = var.region
    vault_license   = var.vault_license
    tls_fullchain   = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
    tls_private_key = acme_certificate.certificate.private_key_pem
  }
}

################################################################################
# Instance Profile
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault-kms-unseal" {
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
  }
}

resource "aws_iam_role" "vault-kms-unseal" {
  name               = "vault-kms-role-${var.owner}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "vault-kms-unseal" {
  name   = "Vault-KMS-Unseal-${var.owner}"
  role   = aws_iam_role.vault-kms-unseal.id
  policy = data.aws_iam_policy_document.vault-kms-unseal.json
}

resource "aws_iam_instance_profile" "vault-kms-unseal" {
  name = "vault-kms-unseal-${var.owner}"
  role = aws_iam_role.vault-kms-unseal.name
}

################################################################################
# aws instance
resource "aws_instance" "hashistack" {
#  for_each                    = data.aws_subnet_ids.subnets.ids
  for_each                    = toset(var.subnet_ids)
  ami                         = data.aws_ami.hashistack.id
  instance_type               = var.hashistack_instance_type
  #count                       = var.hashistack_intance_count
  #security_groups            = [aws_security_group.allow_owner.name]
  vpc_security_group_ids      = [aws_security_group.allow_owner.id]
  key_name                    = aws_key_pair.ssh.id
  subnet_id                   = each.value
  associate_public_ip_address = true
  root_block_device           {
    volume_size               = var.hashistack_root_size
  }

  user_data                   = data.template_file.user_data.rendered

  iam_instance_profile        = aws_iam_instance_profile.vault-kms-unseal.id

  tags = {
    Owner                     = var.owner
    Image_Name                = data.aws_ami.hashistack.name
  }
}
