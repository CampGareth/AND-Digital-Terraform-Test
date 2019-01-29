variable "environment_name" {}
variable security_group_ids {
    type = "list"
}
variable "public_subnets" {
    type = "list"
}

resource "aws_elb" "foobar_elb" {
  subnets            = ["${var.public_subnets}"] # Specifying a subnet attached to a VPC allows the aws_elb resource to figure out which VPC it needs to live in. 
  security_groups    = ["${var.security_group_ids}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "foobar_terraform_elb"
    Environment = "${var.environment_name}"
  }
}

output "elb_name" {
  value = "${aws_elb.foobar_elb.name}"
}