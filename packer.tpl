#!/bin/bash
set -eux

systemctl enable --now amazon-ssm-agent 

sudo yum -y install docker awscli perl

echo "AMI_ID = ${ami_id}" > /var/log/ami_id

systemctl enable --now docker

groupadd docker || :
usermod -aG docker ${INSTANCE_USER}

cat > ${INSTANCE_HOME}/variables.json <<'_END'
${variables_json}
_END

cat > ${INSTANCE_HOME}/load-docker.sh <<'_END'
#!/bin/bash
set -eux
curl -SsL http://${artifacts_endpoint}/${ami_image_builder} -o - | docker load

_END
chmod +x ${INSTANCE_HOME}/load-docker.sh

${INSTANCE_HOME}/load-docker.sh

cat > ${INSTANCE_HOME}/build-ami.sh <<'_END'
#!/bin/bash
set -eux

export PACKER_VAR_FILES='-var-file=/tmp/variables.json'
exec docker run --net host -it --rm --name ami-builder \
  -v ${INSTANCE_HOME}/variables.json:/tmp/variables.json \
  -v $PWD:/output/ \
  -e PACKER_VAR_FILES \
  ami-image-builder
_END
chmod +x ${INSTANCE_HOME}/build-ami.sh

cat > ${INSTANCE_HOME}/tag-containers.sh <<'_END'
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

_END
chmod +x ${INSTANCE_HOME}/tag-containers.sh