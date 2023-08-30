#!/bin/sh
sudo podman image build --tag vs-code-rdp-base:latest -f $(dirname $0)/Containerfile.base && \
sudo podman image build --tag vs-code-rdp-services:latest -f $(dirname $0)/Containerfile.services && \
sudo podman stop code-server || echo not running && \
sudo podman run -d --rm --name=code-server \
  -e SUDO_PASSWORD=sudo \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e TZ=Europe/Vienna \
  -p 8443:8443 \
  -p 8080:80 \
  -v /home/robert/Development/htl/lehre/rdp/config:/config \
  -v /home/robert/Development/htl/lehre/rdp/workspace/:/config/workspace \
  --device /dev/rdp_cdev \
  localhost/vs-code-rdp-services:latest 
