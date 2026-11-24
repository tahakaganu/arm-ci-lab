#!/bin/bash
set -euo pipefail
dnf install -y docker git
systemctl enable --now docker
git clone ${repo} /opt/lab
cd /opt/lab
docker build -t lab-controller jenkins/controller
docker build -t lab-agent jenkins/agent
docker network create ci || true
PW=$(aws secretsmanager get-secret-value --region ${region} \
    --secret-id ${admin_secret} --query SecretString --output text)
    docker run -d --name jenkins --network ci --restart unless-stopped \
    -p 8080:8080 -v jenkins_home:/var/jenkins_home \
    -e ADMIN_PASSWORD=$PW -e AWS_REGION=${region} lab-controller