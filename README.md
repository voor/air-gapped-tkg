# Air Gapped TKG

Install TKG into an air-gapped situation that has no connectivity to the internet.

## Assumptions

1. You have `terraform` and aws cli installed on the first box.  You should not need admin rights to install either of these tools.
1. You are a VMware employee or TGK+ customer that has access to the _magic_ bundle of all the containers and binaries for images (this is not provided to regular TKG customers)
1. You have an AWS account that can create VPCs and IAM policies.

## Terraform

1. Create a `terraform.tfvars` file:
    ```
    environment_name = "gapped"

    region = "us-gov-east-1"
    availability_zones = ["us-gov-east-1a", "us-gov-east-1b", "us-gov-east-1c"]

    key_name = "cluster-api-provider-aws"

    # find . -name "*.tar.gz" -type f | sort -u | xargs -I '{}' basename -s '.tar.gz' {}
    # That's not the command, message me to get the actual lists.  This has to be exact.
    containers = [
        # ...
    ]

    # find . -name "*.tar.gz" -type f | sort -u
    # That's not the command, message me to get the actual lists.  This has to be exact.
    image_names = [
        # ...
    ]
    ```
1. Download files that are automatically synced into s3 when terraform is run:
    ```shell
    docker build -t ami-image-builder -f ami-builder.dockerfile . \
      && docker save ami-image-builder | gzip > ami-image-builder.tar.gz
    curl -O -SsL https://github.com/aelsabbahy/goss/releases/download/v0.3.2/goss-linux-amd64
    curl -O -SsL https://github.com/k14s/ytt/releases/download/v0.27.1/ytt-linux-amd64
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
# Download the _magic_ file and extract it, or speak to your Tanzu Specialist to get the files.
curl -o - -SsL http://build-squid.eng.vmware.com/build/mts/release/bora-15961092/publish/lin64/tkg_release/vmware-kubernetes-v1.0.0+vmware.1.tar.gz | tar -xzvf -
aws s3 sync vmware-kubernetes-v1.0.0+vmware.1 s3://$(terraform output artifact_bucket)/packages/ --exclude "*.ova" --exclude "*.src.rpm" --exclude "*.deb"
# Sync up special TKG CLI that allows government regions and overriding the AMI ID.
aws s3 cp blahblah s3://$(terraform output artifact_bucket)/packages/tanzu_tkg-cli-v1.0.0+vmware.1/executables/tkg-linux-amd64-v1.0.0+vmware.1.gov.gz
```

## Build the Image

Jump onto the box, tag the containers and build the AMI:

```shell
# Assumes you have properly configured SSM for ssh tunneling.
ssh ec2-user@$(terraform output packer_instance_id)
```

```shell
# Make sure you sync the files prior to running this.
./grab-artifacts.sh
./run-once.sh
./build-ami.sh
./run.sh init -i aws -p private
./run.sh create cluster stayathome -p private -c 3 -w 4
```

