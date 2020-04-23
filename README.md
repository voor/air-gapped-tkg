# Air Gapped TKG

Install TKG into an air-gapped situation that has no connectivity to the internet.

Create a `terraform.tfvars` file:
```
environment_name = "gapped"

region = "us-gov-east-1"
availability_zones = ["us-gov-east-1a", "us-gov-east-1b", "us-gov-east-1c"]
```

```
terraform init
terraform plan -out=main.tfplan
terraform apply "main.tfplan"
```

## Loading up the CDS S3 Bucket

Everything we'll need will go into the S3 bucket.  The only exceptions are needing an Amazon 2 Linux VM, access to an Amazon 2 Linux AMI, and any packages that are readily available in the Amazon Linux 2 Repositories.

Put the following into the S3 bucket:
 * Tanzu Kubernetes Grid release tgz file.

Now build the image-builder container that will run packer inside the environment, then save it out, then transfer it.

```
docker build -t ami-image-builder -f ami-builder.dockerfile .
docker save ami-image-builder | gzip > ami-image-builder.tar.gz
```


Jump onto the box and build the AMI:

```
docker load -i ami-image-builder.tar.gz
export MACHINE_OS="amazon-2"
docker run \
    --net host -it --rm \
    --name ami-builder \
    -e "MACHINE_OS=${MACHINE_OS}" \
    -v `pwd`/packer/kubernetes.json:/image-builder/images/capi/packer/config/kubernetes.json \
    -v `pwd`/packer/cni.json:/image-builder/images/capi/packer/config/cni.json \
    -v `pwd`/packer/ami-default.json:/image-builder/images/capi/packer/ami/ami-default.json \
    -v `pwd`/packer/import.sh:/tmp/import.sh \
    -v `pwd`/packer/kubeadmpull.yml:/image-builder/images/capi/ansible/roles/kubernetes/tasks/kubeadmpull.yml \
    ami-image-builder \
    packer build \
    -only=${MACHINE_OS} \
    -var-file=/image-builder/images/capi/packer/config/kubernetes.json \
    -var-file=/image-builder/images/capi/packer/config/cni.json \
    -var-file=/image-builder/images/capi/packer/config/containerd.json \
    -var-file=/image-builder/images/capi/packer/config/ansible-args.json \
    -var-file=/image-builder/images/capi/packer/ami/ami-default.json \
    /image-builder/images/capi/packer/ami/packer.json
