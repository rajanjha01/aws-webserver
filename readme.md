
## Terraform Project to create a Loadbalanced website hosted on AWS cloud.

Architecture : 

- Elastic Load Balancer in public subnet.

- Amazon EC2 instances in different az's and private subnets.

- Security group on Load Balancer permitting port 80 & 443 from 0.0.0.0/0.

- Security group on instances permitting port 80 from the Load Balancer security group.

- An HTTPS certificate for the domain.

- An Amazon Route 53 Hosted Zone with a CNAME record set pointing to the DNS Name of the Load Balancer.

Prerequisite -

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


Usage :

To run this example you need to execute:

$ terraform init # Make sure it installs all the required modules.
$ terraform validate
$ terraform plan 
$ terraform apply


