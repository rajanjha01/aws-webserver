// --- AWS provider variables ---

variable "aws_region" {}
variable "sg_name" {}
variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "instance-type" {}
variable "ps-useast1a" {}
variable "domain_name" {}

