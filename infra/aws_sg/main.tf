variable "environment_name" {}
variable "vpc_id" {}

resource "aws_security_group" "allow_port_80" {
  name        = "allow_port_80"
  description = "Allow inbound traffic on port 80, outbound to all"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment_name}"
  }
}

output "sg_id" {
  value = "${aws_security_group.allow_port_80.id}"
}