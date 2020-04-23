#!/bin/bash
set -eux
# Helps debug instance startup issues by outputting to the system console.
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

systemctl enable --now amazon-ssm-agent 

sudo yum -y install docker awscli perl

echo "AMI_ID = ${ami_id}" > /var/log/ami_id

systemctl enable --now docker

cat > /root/variables.json <<'_END'
${variables_json}
_END

cat > /root/load-docker.sh <<'_END'
#!/bin/bash
set -eux
curl http://${artifacts_endpoint}/ami-image-builder.tar.gz -o - | docker load

_END
chmod +x /root/load-docker.sh

cat > /root/build-ami.sh <<'_END'
#!/bin/bash
set -eux

export PACKER_VAR_FILES='-var-file=/tmp/variables.json'
exec docker run --net host -it --rm --name ami-builder \
  -v /root/variables.json:/tmp/variables.json \
  -e PACKER_VAR_FILES \
  ami-image-builder
_END
chmod +x /root/build-ami.sh