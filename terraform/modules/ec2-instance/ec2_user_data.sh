#!/bin/bash

sudo apt-get update

sudo apt-get install docker.io -y
sudo systemctl start docker

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip -o -q awscliv2.zip
sudo ./aws/install --update

sudo apt-get install -y snapd unzip
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service