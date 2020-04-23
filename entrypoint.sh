#!/bin/bash
set -e

exec /usr/local/bin/packer build \
  ${PACKER_ARGS} \
  -var-file="/image-builder/images/capi/packer/config/kubernetes.json" \
  -var-file="/image-builder/images/capi/packer/config/cni.json" \
  -var-file="/image-builder/images/capi/packer/config/containerd.json" \
  -var-file="/image-builder/images/capi/packer/config/ansible-args.json" \
  -var-file="/image-builder/images/capi/packer/ami/ami-default.json" \
  ${PACKER_VAR_FILES} \
  $@ \
  packer/ami/packer.json \
