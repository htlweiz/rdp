#!/bin/sh
#
# * autocheck RDP_CUSE_MAJOR
# * netaardvark-dns
# * Try in WSL2 (debian)

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
export RDP_CUSE_MAJOR=238

# while ls /dev | grep ${RDP_CUSE_MAJOR}, | grep -v rdp_cdev; do
#   echo ${RDP_CUSE_MAJOR} already taken as major device
#   $(( RDP_CUSE_MAJOR=RDP_CUSE_MAJOR+1 ))
# done
# export RDP_CUSE_MAJOR
# echo Using RDP_CUSE_MAJOR ${RDP_CUSE_MAJOR}


export STATION_ID=0

[ -n "$1" ] && STATION_ID=$1

# export PUID=$(id -u)
# export PGID=$(id -g)

export BASE_PORT=$(( 8000 + 5*STATION_ID ))
export CODE_PORT=$(( BASE_PORT + 1 ))
export LVIM_PORT=$(( BASE_PORT + 2 ))
mkdir -p ./volumes/

stepinfo requirements

which podman || fail 1 no podman installed
which podman-compose || fail 1 no podman-compose installed
which slirp4netns || fail no slirp4netns installed
ldconfig -p | grep fuse3 || fail 2 no fuse installed

stepinfo submodules

git submodule | while read sub_module_line; do
  submodule=$(echo ${sub_module_line} | cut -d \  -f 2)
  if [ -e "./${submodule}/.git" ]; then
    echo sub ${submodule} OK
  else 
    fail 1 submodule ${submodule} missing
  fi
done

stepinfo copyskel

if [ ! -e ./volumes/${STATION_ID} ]; then
  cp -a ./volumes.skel ./volumes/${STATION_ID}
  for repo in ./volumes/${STATION_ID}/workspace/*; do
    echo checking repo ${repo}
    if [ ! -d ${repo}/.git ] && [ -e ${repo}/.git ]; then
      echo found a repo in ${repo}
      cd ${repo}
      rm -rf .git
      git init .
      git add .
      git commit -m "inital commit"
      cd -
    fi
  done
fi


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

podman image build --tag code-base:latest -f ./containerfiles/code/Containerfile.base 2>&1 > logs/build.log || fail 10 build code base failed && \
podman image build --tag device-base:latest -f ./containerfiles/device/Containerfile.base 2>&1 >> logs/build.log || fail 10 build device base failed && \

stepinfo build

podman-compose --project-name rdp_station_${STATION_ID} build 2>&1 | tee -a logs/build.log |  tail -n 1 | grep "exit code: 0$" > /dev/null ||  fail 10 build failed

stepinfo up

podman-compose --in-pod 1 --project-name rdp_station_${STATION_ID} up --no-start > logs/run${STATION_ID}.log 2>&1 || fail 10 up failed
podman pod start pod_rdp_station_${STATION_ID} >> logs/run${STATION_ID}.log 2>&1 || fail 10 run failed

echo Code is accessable at port ${CODE_PORT}
echo App and api is accessable at port ${BASE_PORT}

[ -z ${SILENT} ] && {
  sleep 10
  xdg-open http://localhost:${CODE_PORT} >/dev/null 2>&1
  xdg-open http://localhost:${BASE_PORT} >/dev/null 2>&1
} &
