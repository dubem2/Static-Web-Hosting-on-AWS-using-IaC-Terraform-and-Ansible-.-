# Terraform project
## Objective
The aim of this project is to set up infrastructure on Amazon Web Services (AWS) using Terraform.

#### I created a Terraform template to accomplish the following tasks:
- Provisions three EC2 instances and places them behind an Elastic Load Balancer. 
- Exports the public IP addresses of the three instances to a file named "host-inventory." 
- Sets up AWS Route53 within the Terraform plan and add an A record for a subdomain "terraform-test" that points to the Elastic Load Balancer IP address.

#### I then wrote an Ansible script that performs the following actions:
- Uses the "host-inventory" file to install Apache. 
- Sets the timezone to Africa/Lagos. 
- Displays a simple HTML page on all three EC2 instances that includes content to clearly identify each instance.

#### The infrastructure consists of:
- A virtual private cloud (VPC) with a specified CIDR block.
- A security group that allows incoming HTTP and SSH traffic.
- An internet gateway attached to the VPC A route table associated with the VPC and routing internet traffic to the internet gateway 
- Three EC2 instances with specified AMI, instance type, security group, subnet, keypair, availability zone, and tags 
- Two subnets with specified VPC, CIDR block, public IP mapping, availability zone, and tags 
- An application load balancer with specified name, type, security groups, and subnets dependent on the three EC2 instances.

#### Prerequisites
- Terraform was installed before I worked on this repository. Installation information is available in the [install guide](https://developer.hashicorp.com/terraform/downloads) 
- AWS cli was installed and set up using the **aws configure** command and inputing the **access_key** and the **secret_key** of an IAM user that has admin user permissions. 

#### Usage
Review the code, especially the altschool.tf,variable.tf and route53.tf to understand all the concepts associated with creating an AWS VPC, security group, subnets, internet gateway, route table, and route table association.

Next, run terraform init Then run terraform plan And finally run terraform apply
