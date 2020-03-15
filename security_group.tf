################################################################################
# remote access from home
resource "aws_security_group" "allow_owner" {
  name          = "allow_owner"
  description   = "Allow all traffic from owner ip"
  vpc_id        = data.aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.owner_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = var.owner
  }
}
