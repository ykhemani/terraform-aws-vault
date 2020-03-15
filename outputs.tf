################################################################################
# outputs

#output "subnet_cidr_blocks" {
#  value = [for s in data.aws_subnet.subnet : s]
#}

output "public_ip" {
  value = {
    for instance in aws_instance.hashistack:
      instance.id => instance.public_ip
  }
}
