#!/bin/sh

cd $(dirname $0)

fail() {
  exit_code=$1; shift;
  echo "Error: " $* >&2
  exit ${exit_code}
}

stepinfo() {
  echo 
  echo
  echo
  echo ----------------------------------------------------------------------
  echo $@
  echo ----------------------------------------------------------------------
  echo
}

stepinfo setup

export CUSE_MAJOR=$(ls -l /dev/cuse | sed "s/.*root\ //" | cut -d , -f 1 | xargs echo | cut -d \  -f 1)
export CUSE_MINOR=$(ls -l /dev/cuse | sed "s/.*root\ //" | cut -d , -f 2 | xargs echo | cut -d \  -f 1)
export RDP_CUSE_MAJOR=230
export STATION_ID=0

[ -n "$1" ] && STATION_ID=$1

# export PUID=$(id -u)
# export PGID=$(id -g)

export BASE_PORT=$(( 8000 + 5*STATION_ID ))
export CODE_PORT=$(( BASE_PORT + 1 ))
export LVIM_PORT=$(( BASE_PORT + 2 ))

stepinfo copyskel

[ -e ./volumes/${STATION_ID} ] || cp -a ./volumes.skel ./volumes/${STATION_ID}

stepinfo checkcuse

[ -z ${CUSE_MAJOR}  ] && fail 1 no cuse
[ -z ${CUSE_MINOR}  ] && fail 2 no cuse

stepinfo stop

podman-compose --project-name rdp_station_${STATION_ID} stop
podman-compose --project-name rdp_station_${STATION_ID} down

stepinfo set trap

trap "echo The script is terminated; podman-compose down --project-name rdp_station_${STATION_ID}; exit" SIGINT

stepinfo mknods ...

sudo chmod 666 /dev/cuse || fail 3 chmod failed
[ -e /dev/rdp_cdev${STATION_ID} ] && {
  sudo rm /dev/rdp_cdev${STATION_ID} || fail 4 removal failed
}
sudo mknod --mode 666 /dev/rdp_cdev${STATION_ID} c ${RDP_CUSE_MAJOR} ${STATION_ID} || fail 4 mknod failed
sudo chmod 666 /dev/rdp_cdev${STATION_ID} || fail 4 chmod failed

stepinfo buildbase

sudo podman image build --tag code-base:latest -f ./containerfiles/code/CodeBase.Containerfile 2>&1 > logs/build.log || fail 10 build base failed && \
# sudo podman image build --tag vs-code-rdp-services:latest -f $(dirname $0)/Containerfile.servic

stepinfo build

podman-compose --project-name rdp_station_${STATION_ID} build 2>&1 | tee -a logs/build.log |  tail -n 1 | grep "exit code: 0$" > /dev/null ||  fail 10 build failed

stepinfo up

podman-compose --in-pod 1 --project-name rdp_station_${STATION_ID} up --no-start > logs/run${STATION_ID}.log 2>&1 || fail 10 up failed
podman pod start pod_rdp_station_${STATION_ID} >> logs/run${STATION_ID}.log 2>&1 || fail 10 run failed

echo Code is accessable at port ${CODE_PORT}
echo App and api is accessable at port ${BASE_PORT}

{
  sleep 10
  xdg-open http://localhost:${CODE_PORT} >/dev/null 2>&1
  xdg-open http://localhost:${BASE_PORT} >/dev/null 2>&1
} &
