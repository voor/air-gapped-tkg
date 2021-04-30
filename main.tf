
/*
 * Variables
 */
variable "environment_name" {
  type = string
}

variable "region" {
  type = string
}

variable "key_name" {
  type = string
}

variable "tags" {
  description = "Key/value tags to assign to all resources."
  default     = {}
  type        = map(string)
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

/*
 * Security Groups
 */
resource "aws_security_group" "infrastructure_security_group" {
  name        = "infrastructure_security_group"
  description = "Infrastructure Security Group"
  vpc_id      = data.aws_vpc.vpc.id

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

  tags = merge(var.tags, map("Name", "${var.environment_name}-infrastructure-security-group"))
}
