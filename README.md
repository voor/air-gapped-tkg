# Air Gapped TKG

Install TKG into an air-gapped situation that has no connectivity to the internet.

## Assumptions

1. The example assumes you have an AWS profile configured called "gov", just change things if that is not the case.
1. You are a VMware employee or TGK+ customer that has access to the _magic_ bundle of all the containers and binaries for images (this is not provided to regular TKG customers)
1. You have an AWS account that can create VPCs and IAM policies.

## Terraform

1. Create a `terraform.tfvars` file:
    ```
    environment_name = "gapped"

    region = "us-gov-east-1"
    availability_zones = ["us-gov-east-1a", "us-gov-east-1b", "us-gov-east-1c"]

    key_name = "cluster-api-provider-aws"
    ```
1. Download files that are automatically synced into s3 when terraform is run:
    ```shell
    docker build -t ami-image-builder -f ami-builder.dockerfile . \
    && docker save ami-image-builder | gzip > ami-image-builder.tar.gz
    curl -O -SsL https://github.com/aelsabbahy/goss/releases/download/v0.3.2/goss-linux-amd64
    ```
1. Run terraform:
    ```shell
    terraform init
    terraform plan -out=main.tfplan
    terraform apply "main.tfplan"
    ```

## Finish Loading up the CDS S3 Bucket

Everything we'll need will go into the S3 bucket.  The only exceptions are needing an Amazon 2 Linux VM, access to an Amazon 2 Linux AMI, and any packages that are readily available in the Amazon Linux 2 Repositories.

Put the following into the S3 bucket:
 * Tanzu Kubernetes Grid release tgz contents necessary (RPMs, containers, and cri-containerd tar.gz)
 * goss binary for packer (already there from terraform)
 * AMI builder docker container (already there from terraform)
 * tkg CLI

```shell
# Download the _magic_ file and extract it.
curl -o - -SsL http://build-squid.eng.vmware.com/build/mts/release/bora-15961092/publish/lin64/tkg_release/vmware-kubernetes-v1.0.0+vmware.1.tar.gz | tar -xzvf -
aws --profile gov s3 sync vmware-kubernetes-\*/ s3://$(terraform output artifact_bucket)/packages/ --exclude "*.ova" --exclude "*.src.rpm" --exclude "*.deb"
```

## Build the Image

Jump onto the box, load the docker file, and build the AMI:

```shell
# Assumes you have properly configured SSM for ssh tunneling.
ssh ec2-user@$(terraform output packer_instance_id)
```

```shell
sudo su -
./load-docker.sh
./build-ami.sh
```

