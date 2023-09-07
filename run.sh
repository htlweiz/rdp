#!/bin/sh

stop_container() {
  sudo podman stop code-server || echo container not running
  sudo podman container rm code-server || echo no container
  return 0
}

sudo podman image build --tag vs-code-rdp-base:latest -f $(dirname $0)/Containerfile.base && \
sudo podman image build --tag vs-code-rdp-services:latest -f $(dirname $0)/Containerfile.services && \
stop_container && \
sudo mknod --mode=666 /dev/rdp_cdev c 234 0 
sudo rm $(dirname $0)/workspace/logs/*.log
sudo podman run -d --rm --name=code-server \
  -e SUDO_PASSWORD=sudo \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  -e TZ=Europe/Vienna \
  -p 8443:8443 \
  -p 8080:80 \
  -v $(dirname $0)/config:/config \
  -v $(dirname $0)/workspace/:/config/workspace \
  --device /dev/cuse \
  --device /dev/rdp_cdev \
  localhost/vs-code-rdp-services:latest 
