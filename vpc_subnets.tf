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

data "aws_vpc" "vpc" {
  id = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "private_subnet" {
  count = length(var.availability_zones)

  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(
    var.tags,
    { Name = "${var.environment_name}-private-subnet-${count.index}" },
    { "kubernetes.io/role/internal-elb" = "1" }
  )
}

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