
# let's find our VPC
data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = [var.vpc_name]
  }
}

// # get subnets
// data "aws_subnet_ids" "subnets" {
//   vpc_id = data.aws_vpc.vpc.id
//   filter {
//     name   = "cidr-block"
//     values = [var.subnet_cidr_blocks]
//   }
// }
//
// data "aws_subnet" "subnet" {
//   for_each = data.aws_subnet_ids.subnets.ids
//   id       = each.value
// }
