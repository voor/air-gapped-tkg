# Air Gapped TKG

Install TKG into an air-gapped situation that has no connectivity to the internet.

Create a `terraform.tfvars` file:
```
environment_name = "gapped"

region = "us-gov-east-1"
availability_zones = ["us-gov-east-1a", "us-gov-east-1b", "us-gov-east-1c"]
```

```shell
terraform init
terraform plan -out=main.tfplan
terraform apply "main.tfplan"
```

## Loading up the CDS S3 Bucket

Everything we'll need will go into the S3 bucket.  The only exceptions are needing an Amazon 2 Linux VM, access to an Amazon 2 Linux AMI, and any packages that are readily available in the Amazon Linux 2 Repositories.

Put the following into the S3 bucket:
 * Tanzu Kubernetes Grid release tgz file.

Now build the image-builder container that will run packer inside the environment, then save it out, then transfer it.

```shell
docker build -t ami-image-builder -f ami-builder.dockerfile . \
  && docker save ami-image-builder | gzip > ami-image-builder.tar.gz
aws --profile gov s3 cp ami-image-builder.tar.gz s3://$(terraform output artifact_bucket)/builders/
aws --profile gov s3 sync ~/Downloads/tkg_release/ s3://$(terraform output artifact_bucket)/packages/ --exclude "*" --include "*.rpm" --exclude "*.src.rpm" --include "*/images/*" --include "*/images/*" --include "*cri-containerd*"
```


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