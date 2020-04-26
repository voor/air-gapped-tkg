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

variable "key_name" {
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
    { "kubernetes.io/role/internal-elb" = "1" }
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

resource "aws_vpc_endpoint" "ec2messages" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
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

resource "aws_vpc_endpoint" "sts" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ecr_api" {

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "s3" {

  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  # policy = data.aws_iam_policy_document.cds-endpoint-policy.json
}

resource "aws_main_route_table_association" "main_route_table_association" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_main_route_table_association" {
  route_table_id  = aws_route_table.main_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.environment_name}-packages-artifacts-${random_string.bucket_suffix.result}"
  acl    = "private"

  region = var.region

  policy = data.aws_iam_policy_document.s3_artifacts_policy.json

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = merge(
    var.tags,
    { "Name" = "${var.environment_name}-packages-bucket-${random_string.bucket_suffix.result}" },
  )

}

output "artifact_bucket" {
  value = aws_s3_bucket.artifacts.bucket
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

  tags = merge(var.tags, map("Name", "${var.environment_name}-infrastructure-security-group"))
}

variable "containers" {
  default     = []
  description = "The list of containers that should be preloaded onto the AMI and accessible at runtime."
  type        = list
}

variable "kubernetes_semver" {
  default     = "v1.17.3+vmware.2"
  description = "Version of Kubernetes"
}

variable "image_names" {
  default     = []
  description = "The list images that should be preloaded onto the AMI and accessible at runtime."
  type        = list
}

resource "aws_ecr_repository" "kubernetes_container_registry" {
  count = length(var.containers)
  name  = basename(element(var.containers, count.index))
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



  kubernetes_rpm_version        = "1.17.3-1.el7.vmware.2"
  kubernetes_container_registry = "${element(aws_ecr_repository.kubernetes_container_registry, 0).registry_id}.dkr.ecr.${var.region}.amazonaws.com"

  endpoint = "http://${aws_s3_bucket.artifacts.website_endpoint}/packages"

  rpms = [
    "${local.endpoint}/rpms/cri-tools-1.16.1-1.el7.vmware.3.x86_64.rpm",
    "${local.endpoint}/rpms/kubeadm-${local.kubernetes_rpm_version}.x86_64.rpm",
    "${local.endpoint}/rpms/kubectl-${local.kubernetes_rpm_version}.x86_64.rpm",
    "${local.endpoint}/rpms/kubelet-${local.kubernetes_rpm_version}.x86_64.rpm",
    "${local.endpoint}/rpms/kubernetes-cni-0.7.5-1.el7.vmware.6.x86_64.rpm"
  ]
  variables_json = {
    aws_region  = var.region
    ami_regions = var.region
    vpc_id      = aws_vpc.vpc.id
    subnet_id   = element(aws_subnet.private_subnet.*.id, 0)
    ami_groups  = "all"

    kubernetes_series      = "v1.17"
    kubernetes_semver      = var.kubernetes_semver
    kubernetes_rpm_version = local.kubernetes_rpm_version

    kubernetes_container_registry = local.kubernetes_container_registry

    containerd_pause_image = "${local.kubernetes_container_registry}/pause:3.1"

    kubernetes_source_type = "s3"

    # Need to do a workaround until this becomes available to skip.
    # iam_instance_profile = aws_iam_instance_profile.nodes.id

    # Obviously the kernel is installed so this is essentially a no-op.
    common_redhat_epel_rpm = "kernel"

    containerd_url    = "${local.endpoint}/containerd-v1.3.3+vmware.1/executables/cri-containerd-v1.3.3+vmware.1.linux-amd64.tar.gz"
    containerd_sha256 = "4aed1fd2803525b84700ac427c10e8b7cf0766cc71bc470ff564785432ddf550"

    extra_rpms = "\"${join(" ", local.rpms)}\""

    goss_url        = "${aws_s3_bucket.artifacts.website_endpoint}/builders/goss-linux-amd64"
    manifest_output = "/output/ami.json"

    ecr_b64AuthorizationToken = "ECR_B64AUTHORIZATIONTOKEN"
  }

  templatefile_vars = {
    variables_json = jsonencode(local.variables_json)

    ami_id             = data.aws_ami.amazon_linux_hvm_ami.id
    artifacts_endpoint = aws_s3_bucket.artifacts.website_endpoint
    ami_image_builder  = aws_s3_bucket_object.ami_image_builder.id
    ytt                = aws_s3_bucket_object.ytt.id
    vpc_id             = aws_vpc.vpc.id

    INSTANCE_USER = "ec2-user"
    INSTANCE_HOME = "/home/ec2-user"

    kind_image                    = "kind-v0.7.0-1.17.3+vmware.2/images/node-v1.17.3_vmware.2.tar.gz"
    kubernetes_container_registry = local.kubernetes_container_registry

    containers  = var.containers
    image_names = var.image_names
    region      = var.region
    key_name    = var.key_name
  }


}

output "variables_json" {
  value     = jsonencode(local.variables_json)
  sensitive = true
}

output "template" {
  value     = templatefile("packer.tpl", local.templatefile_vars)
  sensitive = true
}
resource "aws_instance" "packer" {

  ami                  = data.aws_ami.amazon_linux_hvm_ami.id
  instance_type        = "t3.small"
  user_data            = templatefile("packer.tpl", local.templatefile_vars)
  iam_instance_profile = aws_iam_instance_profile.packer.id

  key_name = var.key_name

  subnet_id = aws_subnet.private_subnet.0.id

  vpc_security_group_ids = [aws_security_group.infrastructure_security_group.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 150
  }

}

output "packer_instance_id" {
  value = aws_instance.packer.id
}

/*
 * Provider
 */

provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "gov"
}

provider "random" {
  version = "~> 2.2"
}

terraform {
  required_version = ">= 0.12.0"
}

/*
 * Files
 */
resource "aws_s3_bucket_object" "ami_image_builder" {
  bucket = aws_s3_bucket.artifacts.bucket
  key    = "builders/ami-image-builder.tar.gz"
  source = "ami-image-builder.tar.gz"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("ami-image-builder.tar.gz")
}

resource "aws_s3_bucket_object" "goss-linux-amd64" {
  bucket = aws_s3_bucket.artifacts.bucket
  key    = "builders/goss-linux-amd64"
  source = "goss-linux-amd64"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("goss-linux-amd64")
}

resource "aws_s3_bucket_object" "ytt" {
  bucket = aws_s3_bucket.artifacts.bucket
  key    = "builders/ytt-linux-amd64"
  source = "ytt-linux-amd64"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("ytt-linux-amd64")
}
