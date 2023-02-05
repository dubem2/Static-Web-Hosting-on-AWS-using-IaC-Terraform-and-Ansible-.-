
#create VPC
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "altschool-production"
  }
}

#create Internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myVPC.id
}

#create route table
resource "aws_route_table" "myRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "myRouteTable"
  }
}

#create subnets
resource "aws_subnet" "publicSubnet-1" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = var.subnet_prefix[0]
  availability_zone = "us-east-1a"
  tags = {
    Name = "prod-subnet"
  }  
}
resource "aws_subnet" "publicSubnet-2" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = var.subnet_prefix[1]
  availability_zone = "us-east-1b"
  tags = {
    Name = "dev-subnet"
  } 
} 

resource "aws_subnet" "publicSubnet-3" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = var.subnet_prefix[2]
  availability_zone = "us-east-1c"
  tags = {
    Name = "test-subnet"
  } 
} 
#associate subnets to route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.publicSubnet-1.id
  route_table_id = aws_route_table.myRT.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.publicSubnet-2.id
  route_table_id = aws_route_table.myRT.id
}
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.publicSubnet-3.id
  route_table_id = aws_route_table.myRT.id
}

#create security group to allow port 22,80,443
resource "aws_security_group" "altschool-sg" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_access"
  }
}

#create instances
resource "aws_instance" "web-server1" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "Taskswithgunz"
  security_groups = [aws_security_group.altschool-sg.id]
  subnet_id = aws_subnet.publicSubnet-1.id
  associate_public_ip_address = true
     tags = {
    Name = "web1"
  } 
}
resource "aws_instance" "web-server2" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = "Taskswithgunz"
  security_groups = [aws_security_group.altschool-sg.id]
  subnet_id = aws_subnet.publicSubnet-2.id
  associate_public_ip_address = true
     tags = {
    Name = "web2"
  } 
}
resource "aws_instance" "web-server3" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  availability_zone = "us-east-1c"
  key_name = "Taskswithgunz"
  security_groups = [aws_security_group.altschool-sg.id]
  subnet_id = aws_subnet.publicSubnet-3.id
  associate_public_ip_address = true
     tags = {
    Name = "web3"
  } 
}

# Create a file to store the IP addresses of the instances
resource "local_file" "Ip_address" {
  filename = "/home/vagrant/miniproject/host-inventory"
  content  = <<EOT
${aws_instance.web-server1.public_ip}
${aws_instance.web-server2.public_ip}
${aws_instance.web-server3.public_ip}
  EOT
}

# Create a new load balancer
resource "aws_lb" "altschool-LB" {
  name               = "altschool-alb"
  load_balancer_type = "application"
  #availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  internal = false
  security_groups = [aws_security_group.altschool-sg.id]
  subnets = [aws_subnet.publicSubnet-3.id, aws_subnet.publicSubnet-2.id, aws_subnet.publicSubnet-1.id]

  tags = {
    Name = "altschool-alb"
  }
}

#create listener
resource "aws_lb_listener" "altschool_alb_http_listener" {
  load_balancer_arn = aws_lb.altschool-LB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
  tags = {
    Name = "altschool-alb-listener"
  }  
}

#create target group
resource "aws_lb_target_group" "alb-tg" {
  name        = "altschool-alb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myVPC.id

  health_check {
    path                = "/"               
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }  
}

#register instances to target group
resource "aws_lb_target_group_attachment" "altschool-alb-tg1" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.web-server1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "altschool-alb-tg2" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.web-server2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "altschool-alb-tg3" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.web-server3.id
  port             = 80 
}

#end
