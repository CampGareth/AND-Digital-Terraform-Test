# AND-Digital-Terraform-Test

This repository is meant to demonstrate the following in Terraform:

### The following infrastructure defined as code: 

- VPC (not default)
- Public/private subnets 
- A Load Balancer (ELB)
- Security Groups 
- Two EC2 instances across availability zones in an Auto Scaling Group
- the instances should run a Web page with a "Hello World" returned

### Advanced features

- Using a terraform module or modules
- create a Dev and Prod environments with the same infra above (LB, EC2)
- this should demonstrate some form of repeatable code 

## TODOs
- Trim container size down
- Clean it up, a lot of 'foobar' names in there
