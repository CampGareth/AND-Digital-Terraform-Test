variable "environment_name" {}
variable "elb_name" {}
variable "launch_configuration_name" {}
variable "public_subnets" {
    type = "list"
}
variable "private_subnets" {
    type = "list"
}


resource "aws_autoscaling_group" "foobar" {
  name_prefix               = "${var.environment_name}"
  max_size                  = 2
  min_size                  = 0
  health_check_grace_period = 1000
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  load_balancers            = ["${var.elb_name}"]
  launch_configuration      = "${var.launch_configuration_name}"
  vpc_zone_identifier       = ["${var.public_subnets}", "${var.private_subnets}"]

  tags = {
    key                 = "Environment"
    value               = "${var.environment_name}"
    propagate_at_launch = true
  }
}