# Air Gapped TKG (VPC only creation light version)

Install TKG into an air-gapped situation that has no connectivity to the internet.

## Assumptions

1. You have `terraform` and aws cli installed on the first box.  You should not need admin rights to install either of these tools.
1. You have an AWS account that can create VPCs and IAM policies.

## Terraform

1. Create a `terraform.tfvars` file:
    ```
    environment_name = "gapped"

    region = "us-gov-east-1"
    availability_zones = ["us-gov-east-1a", "us-gov-east-1b", "us-gov-east-1c"]

    key_name = "cluster-api-provider-aws"
    ```
1. Run terraform:
    ```shell
    terraform init
    terraform plan -out=main.tfplan
    terraform apply "main.tfplan"
    ```
1. Launch an instance into this VPC and make sure to give it a role with the AWS CAPA controller manager (for OSS this is `controllers.cluster-api-provider-aws.sigs.k8s.io`)
1. This role should also allow AWS SSM access, which is the easiest way to get into this environment without a lot of complex AWS transit gateway or AWS peering stuff.
1. You will need to copy files into S3 and then access them from S3 due to the closed off nature of the VPC (unless you were able to peer it into another network).
1. Good luck.