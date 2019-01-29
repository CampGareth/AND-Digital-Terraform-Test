module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "foobar-${var.environment-name}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "${var.environment-name}"
  }
}

resource "aws_security_group" "allow_port_80" {
  name        = "allow_port_80"
  description = "Allow inbound traffic on port 80, outbound to all"
  vpc_id      = "${module.vpc.vpc_id}"

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
    Environment = "${var.environment-name}"
  }
}



resource "aws_iam_instance_profile" "foobar_profile" {
  name = "foobar_profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}


resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ecr:GetLifecyclePolicyPreview",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:GetAuthorizationToken",
                "ecr:DescribeRepositories",
                "ecr:ListTagsForResource",
                "ecr:ListImages",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:GetLifecyclePolicy"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_launch_configuration" "pull_and_run_web_app" {
  name          = "web_server"
  image_id      = "ami-012fd5eb46f56731f"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.foobar_profile.name}" 
  security_groups = ["${aws_security_group.allow_port_80.id}"]
  user_data = <<-EOF
              #!/bin/bash -xe
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              apt-get update
              apt-get install -y docker.io awscli
              systemctl start docker
              aws ecr get-login --region=us-east-1 --no-include-email | sh
              docker pull 259629412777.dkr.ecr.us-east-1.amazonaws.com/campgareth/hello-world-web-app:latest
              docker run -d -e PORT=80 -p 80:80 259629412777.dkr.ecr.us-east-1.amazonaws.com/campgareth/hello-world-web-app:latest
              EOF
}

resource "aws_elb" "foobar-elb" {
  name               = "foobar-terraform-elb"
  subnets            = ["${module.vpc.public_subnets}"] # Specifying a subnet attached to a VPC allows the aws_elb resource to figure out which VPC it needs to live in. 
  security_groups    = ["${aws_security_group.allow_port_80.id}"]

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
    Name = "foobar-terraform-elb"
    Environment = "${var.environment-name}"
  }
}

resource "aws_autoscaling_group" "bar" {
  name_prefix               = "${var.environment-name}"
  max_size                  = 2
  min_size                  = 0
  health_check_grace_period = 1000
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  load_balancers            = ["${aws_elb.foobar-elb.name}"]
  launch_configuration      = "${aws_launch_configuration.pull_and_run_web_app.name}"
  vpc_zone_identifier       = ["${module.vpc.public_subnets}", "${module.vpc.public_subnets}"]

  tags = {
    key                 = "Environment"
    value               = "${var.environment-name}"
    propagate_at_launch = true
  }
}