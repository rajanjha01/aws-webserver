
## Terraform Project to create a Loadbalanced website hosted on AWS cloud

Architecture : 

- Elastic Load Balancer in public subnet.

- Two Amazon EC2 instances in different az's and private subnets.

- Security group on Load Balancer permitting port 80 & 443 from 0.0.0.0/0.

- Security group on instances permitting port 80 from the Load Balancer security group.

- An HTTPS certificate for the domain.

- An Amazon Route 53 Hosted Zone with a CNAME record set pointing to the DNS Name of the Load Balancer.

## Prerequisites 

AWS -

Configure AWS on your local system and create a profile to assume the role.

- Configure AWS CLI
- Create a source profile with your access key and secret access.
   cat ~/.aws/credentials
   [studocu]
   aws_access_key_id = XXXXXXXXXXXXXXXXXXX
   aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
     
- Create a profile in ~/.aws/config
    [profile studocu]
    region = us-east-1
    role_arn = your_iam_role_arn
    source_profile = studocu

Terraform -

Install Terraform on your system.

Github -

Clone this repo on your local system.


## Usage 

To run this example you need to execute:
$ cd terraform/

$ terraform init # Make sure it installs all the required modules.

$ terraform validate

$ terraform plan 

$ terraform apply 

## Resources

|             Name	                                    |             Type          |
--------------------------------------------------------|----------------------------
|aws_vpc.default                                        |        data source        |
|aws_subnet_ids.public                                  |        data source        |
|aws_availability_zones.allzones                        |        data source        |
|aws_ami.mylinuxami                                     |        data source        |
|aws_route53_zone.studocu                               |        data source        | 
|aws_subnet.webprivate                                  |        private subnets    |
|aws_eip.studocu-EIP                                    |        elastic ip         |
|aws_nat_gateway.studocu-NAT                            |        nat gateway        |
|aws_route_table.studocu-NAT-RT                         |        route table        |
|aws_route_table_association.studocu-Nat-RT-Association |        route table assoc  |
|aws_security_group.websg                               |        instance sg        |
|tls_private_key.key_pair                               |        keypair            |
|aws_key_pair.key_pair                                  |        ker pair           |
|local_file.ssh_key                                     |        saved key pair     |
|aws_instance.studocu-webserver                         |        webserver          |
|module.acm                                             |        acm                |
|aws_security_group.elbsg                               |        lb security group  |
|aws_elb.elb-ws                                         |        elb for web server |
|aws_route53_record.studocu-url                         |        cname record       |

## Outputs

Domain name can be passed using variable domain_name in auto.tfvars file.
| Name         | Description       |
---------------|--------------------
|elb-ws	       |The name of the ELB|
|webserver-url |The complete url   |

Once the apply is complete, output should print the complete fqdn which can be accesed locally. 
A page refresh should show the private ip's of backend instances.




