# terraform-aws-vault

This [Terraform](https://terraform.io) configuration allows you to provision an [Ubuntu](https://ubuntu.com) server on an ec2 instance running in [AWS](https://aws.amazon.com/).

The provisioned instance comes up with [HashiCorp](https://hashicorp.com) [Vault](https://vaultproject.io) Enterprise initialized and licensed, fully unattended. Vault is configured with [integrated Raft storage](https://www.vaultproject.io/docs/configuration/storage/raft/) and uses [AWS KMS Seal](https://www.vaultproject.io/docs/configuration/seal/awskms/).

A DNS record is provisioned in [Cloudflare](https://www.cloudflare.com/), but the configuration can be adapted to create DNS records with other DNS providers.

An [ACME](https://www.terraform.io/docs/providers/acme/r/certificate.html) PKI certificate is provisioned from [LetsEncrypt](https://letsencrypt.org/) using Cloudflare for the DNS challenge.

State is stored in [Terraform Cloud](https://www.terraform.io/docs/cloud/). You can also run this Terraform code in Terraform Cloud.

Do NOT use this Terraform configuration in production. When Vault is initialized, the root token and recovery keys are stored on the filesystem. The purpose of this Terraform configuration is to make doing Vault demos easier.

## Prequisites / Dependencies

### Environment variables
The Terraform code requires you to define the following environment variables.

* `ATLAS_TOKEN` is your Terraform Cloud API token. You can generate this by going to https://app.terraform.io/app/settings/tokens.
* `VAULT_LICENSE` is the text of your Vault Enterprise license.
* `AWS_SECRET_ACCESS_KEY` and `AWS_ACCESS_KEY_ID` are your AWS credentials.
* `CF_API_EMAIL`, `CLOUDFLARE_EMAIL` and `CLOUDFLARE_API_KEY` are your Cloudflare credentials. The reason that we define the Clouldflare email address using two different variables is because `CF_API_EMAIL` is required for the [ACME provider](https://www.terraform.io/docs/providers/acme/dns_providers/cloudflare.html) and `CLOUDFLARE_EMAIL` is required by the [Clouldflare provider](https://www.terraform.io/docs/providers/cloudflare/index.html). You can generate a Cloudflare API key by logging into your Cloudflare account, clicking on *My Profile* in the menu on the top right, and then selecting API Tokens.

### Terraform variables
A number of the Terraform variables in this configuration have defaults that you can use. Others are required and must be configured. The variables are documented via the descriptions in the [variables.tf](blob/variables.tf) file, so we won't repeat the definitions here. The variables you must define do not have defaults defined in `variables.tf`. The variables you must define are listed in the [terraform.tfvars.example](blob/terraform.tfvars.example) file (except for `owner_ip`). You can make a copy of this file and save it as `terraform.tfvars`, or you can define these variables as `TF_VAR_<variable_name>`.

The `owner_ip` is your IP address. We allow full access from this IP address to the instance that is provisioned. The assumption is that you are going to run this from your home or office network, and the [tf.sh](blob/tf.sh.example) script will connect to [ipconfig.io](https://ipconfig.io) to determine your public IP address. If this is not a good assumption for your use, modify the [security group definition](blob/security_group.tf) appropriately.

### Remote State Storage
The [Terraform settings](https://www.terraform.io/docs/configuration/terraform.html) cannot be parameterized via variables. In order to configure [remote state](https://www.terraform.io/docs/backends/types/terraform-enterprise.html), make a copy of [remote.tf.example](blob/remote.tf.example) and save it as `remote.tf` and define your Terraform Cloud organization and workspace.

## Running this Terraform code
There is a [tf.sh.example](blob/tf.sh.example) script that sets the aforementioned environment variables and the `owner_ip` and `vault_license` Terraform variables. The sensitive variables are set in our example by pulling the values from [LastPass](https://www.lastpass.com/) using the [LastPass CLI](https://github.com/lastpass/lastpass-cli). You can make a copy of this script and save it as `tf.sh`, and customize it to pull from your LastPass account or set these environment variables any way you like, but please don't store them in plain text and please do NOT check them into GitHub or other VCS provider, be it public or privately hosted.

### Initialize Terraform
```
./tf.sh init
```

Or if you are running Terraform directly:

```
terraform init
```

### Plan
```
./tf.sh plan
```

Or if you are running Terraform directly:

```
terraform plan
```

### Apply
```
./tf.sh apply
```

Or if you are running Terraform directly:

```
terraform apply
```

### Outputs
* `public_ip` - When you run Terraform, you'll get the public IP address of the instance that you've provisioned.

## Accessing the instance
You can ssh into the instance that was provisioned via the `public_ip` as the `ubuntu` user using the ssh key you provided.

You can also ssh to the DNS record that was provisioned.

## Accessing Vault
When Vault is initialized, the initial root token and the recovery key is stored in the `/etc/vault.d/vault_init_output` file. Additionally, the initial root token is saved as the VAULT_ROOT_TOKEN environment variable in the `/etc/vault.d/vaultrc` file. You can source this file in order to interact with Vault on the instance.

## Troubleshooting
The purpose of this configuration is to allow you to provision Vault Enterprise fully unattended. If something goes wrong, you can examine the following items to see what may have gone wrong.

### Where you ran Terraform
```
./tf.sh show
```

or
```
terraform show
```

### On the instance
* Cloud init logs: `/var/log/cloud-init.log`
* Cloud init output: `cloud-init-output.log`
* User data script that can be identified by running `find /var/lib -name 'part-001'`
* Vault configuration: `/etc/vault.d/vault.hcl`
* Vault initialization output at `/etc/vault.d/vault_init_output`
* Vault PKI certs: /data/vault/ssl/
* Vault data: /data/vault/raft/

---
