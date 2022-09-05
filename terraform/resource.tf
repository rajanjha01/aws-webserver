## get the networking and linux image details for this account
#############################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_availability_zones" "allzones" {}

## get ami id 
data "aws_ami" "mylinuxami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
## get route53 hosted zone id

data "aws_route53_zone" "studocu" {
  name         = "code.studucu.com."
  private_zone = false
}
## Create web server - backend instances, security groups and private subnets for the instances
##############################################

## create two different private subnets for studocu web instances

resource "aws_subnet" "webprivate" {
  vpc_id            = data.aws_vpc.default.id
  count             = length(var.availability_zones)
  cidr_block        = cidrsubnet("172.31.96.0/19", 1, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "Studocu-private-subnet-${count.index}"
  }
}
#########################################
## Create eip for nat
resource "aws_eip" "studocu-EIP" { 
  vpc = true
}

##Cteate a nat gateway for private subnet

resource "aws_nat_gateway" "studocu-NAT" {
  depends_on = [
    aws_eip.studocu-EIP
  ]
  allocation_id = aws_eip.studocu-EIP.id
  subnet_id              = var.ps-useast1a
  tags = {
    Name = "studocu-nat-gateway"
  }
}
## create route table for nat
resource "aws_route_table" "studocu-NAT-RT" {
  depends_on = [
    aws_nat_gateway.studocu-NAT
  ]
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.studocu-NAT.id
  }
  tags = {
    Name = "Route Table for NAT Gateway"
  }

}
## rt association
resource "aws_route_table_association" "studocu-Nat-RT-Association" {
  depends_on = [
    aws_route_table.studocu-NAT-RT
  ] 
  count                  = length(var.availability_zones)
  subnet_id              = aws_subnet.webprivate[count.index].id
  
  route_table_id = aws_route_table.studocu-NAT-RT.id
}

########################################################################
## Create security groups for ec2 instances

resource "aws_security_group" "websg" {
  name        = var.sg_name
  description = "security_group_for_studocuweb_server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTPS Access"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.elbsg.id]
  }
  ingress {
    description     = "HTTP Access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elbsg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "webserverSG"
  }
}

# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "linux-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}

## Create ec2 instances in separate private subnets and avilability zones

resource "aws_instance" "studocu-webserver" {
  depends_on        = [
    aws_nat_gateway.studocu-NAT
    ]  
  count                  = length(var.availability_zones)
  ami                    = data.aws_ami.mylinuxami.id
  instance_type          = var.instance-type
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.webprivate[count.index].id
  key_name               = aws_key_pair.key_pair.key_name
  lifecycle {
    create_before_destroy = true
  }

user_data = <<-EOF
#!/bin/bash
sudo -i
yum install -y httpd.x86_64
service httpd start
echo "$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" > /var/www/html/index.html
service httpd restart
EOF

tags = {
    Name = "studocu-webserver-${count.index}"
  }
}

##Create ELB resources
################################################################

### Create acm certificate for the website using acm public module
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = "code.studucu.com"
  zone_id     = data.aws_route53_zone.studocu.zone_id

  subject_alternative_names = [
    "*.code.studucu.com",
  ]

  wait_for_validation = true

  tags = {
    Name = "code.studucu.com"
  }
}

########################################################
resource "aws_security_group" "elbsg" {
  name   = "security_group_for_elb"
  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "Studocu-webserver-elb-SG"
  }
}

## AWS Elastic load balancer to serve the website

resource "aws_elb" "elb-ws" {
  name               = "elb-webserver"
  availability_zones = var.availability_zones
  security_groups = [aws_security_group.elbsg.id]
  internal        = false

  listener {

    instance_port     = "80"
    instance_protocol = "http"
    lb_port           = "80"
    lb_protocol       = "http"
  }
  listener {
    instance_port      = "80"
    instance_protocol  = "http"
    lb_port            = "443"
    lb_protocol        = "https"
    ssl_certificate_id = module.acm.acm_certificate_arn
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
  instances                   = aws_instance.studocu-webserver.*.id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "project-webserver"
  }

}
## Route 53 record to point to the elb
resource "aws_route53_record" "studocu-url" {
  zone_id = data.aws_route53_zone.studocu.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = "60"
  records = [aws_elb.elb-ws.dns_name]
}

######################################################################