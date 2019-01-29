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

module "vpc_dev" {
  source = "terraform-aws-modules/vpc/aws"

  name = "foobar_dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

module "aws_sg_dev" {
  source = "./aws_sg"
  environment_name = "dev"
  vpc_id = "${module.vpc_dev.vpc_id}"
}

module "aws_lc_dev" {
  source = "./aws_lc"
  iam_instance_profile_name = "${aws_iam_instance_profile.foobar_profile.name}"
  security_group_ids = ["${module.aws_sg_dev.sg_id}"]
}

module "aws_elb_dev" {
  source = "./aws_elb"
  security_group_ids = ["${module.aws_sg_prod.sg_id}"]
  environment_name = "dev"
  public_subnets = "${module.vpc_dev.public_subnets}"
}

module "aws_asg_dev" {
  source = "./aws_asg"
  environment_name = "${var.environment_name}"
  elb_name =  "${module.aws_elb_dev.elb_name}"
  launch_configuration_name = "${module.aws_lc_dev.launch_configuration_name}"
  public_subnets = "${module.vpc_dev.public_subnets}"
  private_subnets = "${module.vpc_dev.private_subnets}"
}

module "vpc_prod" {
  source = "terraform-aws-modules/vpc/aws"

  name = "foobar_prod"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.101.0/24", "10.1.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "prod"
  }
}

module "aws_sg_prod" {
  source = "./aws_sg"
  environment_name = "prod"
  vpc_id = "${module.vpc_prod.vpc_id}"
}

module "aws_lc_prod" {
  source = "./aws_lc"
  iam_instance_profile_name = "${aws_iam_instance_profile.foobar_profile.name}"
  security_group_ids = ["${module.aws_sg_prod.sg_id}"]
}

module "aws_elb_prod" {
  source = "./aws_elb"
  security_group_ids = ["${module.aws_sg_prod.sg_id}"]
  environment_name = "prod"
  public_subnets = "${module.vpc_prod.public_subnets}"
}

module "aws_asg_prod" {
  source = "./aws_asg"
  environment_name = "${var.environment_name}"
  elb_name =  "${module.aws_elb_prod.elb_name}"
  launch_configuration_name = "${module.aws_lc_prod.launch_configuration_name}"
  public_subnets = "${module.vpc_prod.public_subnets}"
  private_subnets = "${module.vpc_prod.private_subnets}"
}
