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