FROM ubuntu:focal

ENV PACKER_ARGS '-only amazon-2'
ENV PACKER_VAR_FILES ''

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates ansible curl wget git rsync vim jq unzip build-essential \
    && curl -sL https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 -o /usr/local/bin/yq \
    && chmod 0777 /usr/local/bin/yq \
    && curl -sL https://github.com/YaleUniversity/packer-provisioner-goss/releases/download/v0.3.0/packer-provisioner-goss-v0.3.0-linux-amd64 -o /usr/local/bin/packer-provisioner-goss \
    && chmod +x /usr/local/bin/packer-provisioner-goss \
    && curl -sL https://releases.hashicorp.com/packer/1.4.5/packer_1.4.5_linux_amd64.zip -o /tmp/packer.zip; unzip /tmp/packer.zip; mv packer /usr/local/bin/packer \
    && rm -rf /tmp/packer.zip \
    && git clone https://github.com/kubernetes-sigs/image-builder.git; cd /image-builder; git checkout ffe8c664; chmod -R 0777 /image-builder \
    && useradd -ms /bin/bash ansible \
    && apt-get purge --auto-remove -y \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /image-builder/images/capi/
USER ansible
WORKDIR /image-builder/images/capi

ENTRYPOINT [ "/image-builder/images/capi/entrypoint.sh" ]