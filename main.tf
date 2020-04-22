/*
 * Variables
 */
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  description = "The list of availability zones to use. Must belong to the provided region and equal the number of CIDRs provided for each subnet."
  type        = list
}

variable "private_subnet_cidrs" {
  default     = ["10.0.12.0/24", "10.0.13.0/24", "10.0.14.0/24"]
  description = "The list of CIDRs for the private subnet. Number of CIDRs MUST match the number of AZs."
  type        = list
}

variable "environment_name" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  description = "Key/value tags to assign to all resources."
  default     = {}
  type        = map(string)
}


/*
 * VPC
 */
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    { Name = "${var.environment_name}" },
  )

}

resource "aws_subnet" "private_subnet" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(
    var.tags,
    { Name = "${var.environment_name}-private-subnet-${count.index}" },
  )
}

resource "aws_vpc_endpoint" "ec2" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ssm" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

/*
 * Security Groups
 */
resource "aws_security_group" "infrastructure_security_group" {
  name        = "infrastructure_security_group"
  description = "Infrastructure Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    cidr_blocks = ["${var.vpc_cidr}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.environment_name}-infrastructure-security-group"))}"
}


/*
 * Packer Builder
 */
data "aws_ami" "amazon_linux_hvm_ami" {
  most_recent = true

  name_regex = "^amzn2-ami-hvm-[0-9.]+-x86_64-ebs$"

  owners = ["amazon"]
}

locals {
  templatefile_vars = {
    ami_id = data.aws_ami.amazon_linux_hvm_ami.id
  }
}

resource "aws_instance" "packer" {

  ami                  = data.aws_ami.amazon_linux_hvm_ami.id
  instance_type        = "t3.small"
  user_data            = templatefile("packer.tpl", local.templatefile_vars)
  iam_instance_profile = aws_iam_instance_profile.packer.id

  subnet_id = aws_subnet.private_subnet.0.id

  vpc_security_group_ids = [aws_security_group.infrastructure_security_group.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 150
  }

}


/*
 * Provider
 */

provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "gov"
}

terraform {
  required_version = ">= 0.12.0"
}

