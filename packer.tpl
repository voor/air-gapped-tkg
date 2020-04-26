#!/bin/bash
set -eux

touch ${INSTANCE_HOME}/not-ready-yet

groupadd docker || :
usermod -aG docker ${INSTANCE_USER}


systemctl enable --now amazon-ssm-agent 

sudo yum -y install docker awscli perl jq

echo "AMI_ID = ${ami_id}" > /var/log/ami_id

systemctl enable --now docker

cat > ${INSTANCE_HOME}/variables.json <<'_END'
${variables_json}
_END

cat > ${INSTANCE_HOME}/load-docker.sh <<'_END'
#!/bin/bash
set -eux
curl -SsL http://${artifacts_endpoint}/${ami_image_builder} -o - | docker load

curl -SsL http://${artifacts_endpoint}/${ytt} -o /usr/local/bin/ytt
chmod +x /usr/local/bin/ytt

_END
chmod +x ${INSTANCE_HOME}/load-docker.sh

${INSTANCE_HOME}/load-docker.sh

cat > ${INSTANCE_HOME}/kubeadm.yml <<'_END'
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
imageRepository: {{ kubernetes_container_registry }}
kubernetesVersion: {{ kubernetes_semver }}
etcd:
  local:
    dataDir: /var/lib/etcd
    imageRepository: ${kubernetes_container_registry}
    imageTag: v3.4.3_vmware.4
dns:
  type: CoreDNS
  imageRepository: ${kubernetes_container_registry}
  imageTag: v1.6.5_vmware.4
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
nodeRegistration:
  criSocket: "/var/run/containerd/containerd.sock"
_END

cat > ${INSTANCE_HOME}/overlay-vpc.yaml <<'_END'
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind":"AWSCluster"})
---
spec:
  region: ${region}
  #@overlay/match missing_ok=True
  sshKeyName: ${key_name}
  #! Set to false to skip creation of bastion host
  bastion:
    #@overlay/match missing_ok=True
    enabled: false
  #@overlay/match missing_ok=True
  controlPlaneLoadBalancer:
    #@overlay/match missing_ok=True
    scheme: internal
  networkSpec:
    #@overlay/remove
    subnets:
    vpc:
      #@overlay/remove
      cidrBlock:
      #@overlay/match missing_ok=True
      id: ${vpc_id}

#@overlay/match by=overlay.subset({"kind":"KubeadmControlPlane"})
---
spec:
  kubeadmConfigSpec:
    clusterConfiguration:
      controllerManager:
        extraArgs:
          #@overlay/match missing_ok=True
          configure-cloud-routes: "false"

_END

cat > ${INSTANCE_HOME}/build-ami.sh <<'_END'
#!/bin/bash
set -eux

export ECR_B64AUTHORIZATIONTOKEN=$(aws ecr get-authorization-token --region ${region} --output text --query 'authorizationData[].authorizationToken')
sed "s/ECR_B64AUTHORIZATIONTOKEN/$ECR_B64AUTHORIZATIONTOKEN/" variables.json > variables-ready.json
export PACKER_VAR_FILES="-var-file=/tmp/variables-ready.json "
exec docker run --net host -it --rm --name ami-builder \
  -v ${INSTANCE_HOME}/variables-ready.json:/tmp/variables-ready.json \
  -v $PWD:/output/ \
  -v ${INSTANCE_HOME}/kubeadm.yml:/image-builder/images/capi/ansible/roles/kubernetes/templates/etc/kubeadm.yml \
  -e PACKER_VAR_FILES \
  ami-image-builder
_END
chmod +x ${INSTANCE_HOME}/build-ami.sh

cat > ${INSTANCE_HOME}/grab-artifacts.sh <<'_END'
#!/bin/bash
set -eux

curl -SsL http://${artifacts_endpoint}/packages/${kind_image} -o - | docker load
%{ for image in image_names ~}
curl -SsL http://${artifacts_endpoint}/packages/${image} -o - | docker load
%{ endfor ~}

eval $(aws ecr get-login --region ${region} --no-include-email)

COL_ONE=($(docker image list --format "{{.Repository}}:{{.Tag}}" | grep -v ami-image-builder | grep -v kind))
COL_TWO=($(docker image list --format "{{.Repository}}:{{.Tag}}" | sed 's/registry.tkg.vmware.run/${kubernetes_container_registry}/g' | sed 's/vmware.io/${kubernetes_container_registry}/g' | grep -v ami-image-builder | grep -v kind))

for ((i=0; i<$${#COL_ONE[@]}; i++)); do
    docker tag "$${COL_ONE[i]}" "$${COL_TWO[i]}"
    docker push "$${COL_TWO[i]}"
done

mkdir -p ~/bin

curl -SsL http://${artifacts_endpoint}/packages/tanzu_tkg-cli-v1.0.0+vmware.1/executables/tkg-linux-amd64-v1.0.0+vmware.1.gov.gz -o - | gunzip > ~/bin/tkg
chmod +x ~/bin/tkg
tkg version
curl -SsL http://${artifacts_endpoint}/packages/kubernetes-v1.17.3+vmware.2/executables/kubectl-linux-v1.17.3+vmware.2.gz -o - | gunzip > ~/bin/kubectl
chmod +x ~/bin/kubectl
kubectl version

tkg get mc

find ${INSTANCE_HOME}/.tkg/ -type f -name "*.yaml" -print0 | xargs -0 sed -i '' -e 's/registry.tkg.vmware.run/${kubernetes_container_registry}/g'

# cert-manager is not in a sub-directory -- this ECR specific.
for pattern in cluster-api cert-manager calico-all ccm csi; do
  find ${INSTANCE_HOME}/.tkg/ -type f -name "*.yaml" -print0 | xargs -0 sed -i '' -e "s|${kubernetes_container_registry}/$${pattern}/|${kubernetes_container_registry}/|g"
done

ytt --ignore-unknown-comments -f /home/ec2-user/.tkg/providers/infrastructure-aws/v0.5.2/cluster-template-dev.yaml -f overlay-vpc.yaml

_END
chmod +x ${INSTANCE_HOME}/grab-artifacts.sh

cat > ${INSTANCE_HOME}/run.sh <<'_END'
#!/bin/bash
set -eux

export AWS_AMI_ID=$(<ami.json jq .builds[0].artifact_id -rc | cut -d ":" -f2-)
export AWS_REGION=${region}
export AWS_SSH_KEY_NAME=${key_name}

# FIXME Hard-coded gov region right now
export AWS_B64ENCODED_CREDENTIALS="W2RlZmF1bHRdCnJlZ2lvbiA9IHVzLWdvdi1lYXN0LTEKCg=="

export AWS_NODE_AZ=${region}a
export AWS_PRIVATE_NODE_CIDR=notused
export AWS_PUBLIC_NODE_CIDR=notused
export AWS_VPC_CIDR=notused

export CONTROL_PLANE_MACHINE_TYPE=t3.large
export NODE_MACHINE_TYPE=t3.large
export CLUSTER_CIDR="100.96.0.0/11"

tkg init -i aws

_END
chmod +x ${INSTANCE_HOME}/run.sh

rm -rf ${INSTANCE_HOME}/not-ready-yet
