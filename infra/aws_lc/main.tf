variable iam_instance_profile_name {}
variable security_group_ids {
    type = "list"
}

resource "aws_launch_configuration" "pull_and_run_web_app" {
  name          = "web_server"
  image_id      = "ami-012fd5eb46f56731f"
  instance_type = "t2.micro"
  iam_instance_profile = "${var.iam_instance_profile_name}" 
  security_groups = ["${var.security_group_ids}"]
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

output "launch_configuration_name" {
  value = "${aws_launch_configuration.pull_and_run_web_app.name}"
}