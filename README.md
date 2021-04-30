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
