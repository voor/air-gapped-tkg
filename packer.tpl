#!/bin/bash
set -eux
# Helps debug instance startup issues by outputting to the system console.
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "AMI_ID = ${ami_id}" > /var/log/ami_id

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
systemctl status amazon-ssm-agent
systemctl status docker