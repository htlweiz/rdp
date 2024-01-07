#!/bin/sh
#
# * autocheck RDP_CUSE_MAJOR
# * netaardvark-dns
# * apt-utils to container
# * Try in WSL2 (debian)

DEBUG=false

cd $(dirname $0)

main() {
  step_setup $*
  step_required_programs podman podman-compose slirp4netns
  step_required_libs fuse3 
  step_git_submodules
  step_copy_skel
  step_build_bases \
    ./containerfiles/code/Containerfile.base code-base:latest \
    ./containerfiles/device/Containerfile.base device-base:latest
  step_build_pod
  step_restart_pod

  fatal 0 Station ID: ${STATION_ID}

  # while ls /dev | grep ${RDP_CUSE_MAJOR}, | grep -v rdp_cdev; do
  #   echo ${RDP_CUSE_MAJOR} already taken as major device
  #   $(( RDP_CUSE_MAJOR=RDP_CUSE_MAJOR+1 ))
  # done
  # export RDP_CUSE_MAJOR
  # echo Using RDP_CUSE_MAJOR ${RDP_CUSE_MAJOR}
}

log() {
  level=$1; shift
  echo ${level}: $@ >&2
}

debug() {
  ${DEBUG} && log DEBUG $@
}

info() {
  log INFO $@
}

warn() {
  log WARN $@
}

error() {
  log ERROR $@
}

fatal() {
  exit_code=$1; shift;
  log ERROR $@ 
  exit ${exit_code}
}

tail_log() {
    fail_level=$1; shift
    log_file=$1; shift
    tail -n 100 ${log_file} | while read -r log_line; do
      error " --> " ${log_line}
    done
    echo
    error info from ${log_file}
    fatal ${fail_level} $@
}

fail() {
  warn DEPRECATION WARNING! usage of fail
  fatal $*
}

step_info() {
  info
  info ----------------------------------------------------------------------
  info --- $@
  info ----------------------------------------------------------------------
  info
}

step_setup() {
  fail_level=1
  step_info SETUP
  export CUSE_MAJOR=$(ls -l /dev/cuse | sed "s/.*root\ //" | cut -d , -f 1 | xargs echo | cut -d \  -f 1)
  export CUSE_MINOR=$(ls -l /dev/cuse | sed "s/.*root\ //" | cut -d , -f 2 | xargs echo | cut -d \  -f 1)
  [ -z "${CUSE_MAJOR}" ] && fatal ${fail_level} No cuse support in kernel.
  info CUSE support OK
  export RDP_CUSE_MAJOR=230

  export STATION_ID=0
  [ -n "$1" ] && STATION_ID=$1
  export BASE_PORT=$(( 8000 + 5*STATION_ID ))

  export CODE_PORT=$(( BASE_PORT + 1 ))
  export LVIM_PORT=$(( BASE_PORT + 2 ))
  info STATION_ID ${STATION_ID}
  info BASE_PORT ${BASE_PORT}
  info CODE_PORT ${CODE_PORT}

  [ -z ${VOLUMES} ] && export VOLUMES=./volumes
  mkdir -p ${VOLUMES} || fatal ${fail_level} Could not create volumes dir ${VOLUMES}
  info Volumes dir ${VOLUMES} is ok

  [ -z "${SKEL_DIR}"] && export SKEL_DIR=./volumes.skel
  export SKEL_CONFIG=${SKEL_DIR}/config
  export SKEL_WORKSPACE=${SKEL_DIR}/workspace

  info SKEL_DIR ${SKEL_DIR}

  export RDP_CDEV=/dev/rdp_cdev${STATION_ID}

  sudo chmod 666 /dev/cuse || fatal ${fail_level} chmod /dev/cuse failed
  [ -e ${RDP_CDEV} ] && {
    sudo rm ${RDP_CDEV} || fatal ${fail_level} removal of ${RDP_CDEV} failed
  }
  sudo mknod --mode 666 ${RDP_CDEV} c ${RDP_CUSE_MAJOR} ${STATION_ID} || fatal ${fail_level} mknod ${RDP_CDEV} failed
  sudo chmod 666 ${RDP_CDEV} || fatal ${fail_level} chmod ${RDP_CDEV} failed
  info created ${RDP_CDEV}
}

step_required_programs() {
  fail_level=2
  step_info REQUREMENTS PROGRAMS
  for program in $*; do
    which ${program} >/dev/null 2>&1 || fatal ${fail_level} ${program} not installed.
    info program ${program} ok
  done
}

step_required_libs() {
  fail_level=3
  step_info REQUREMENTS LIBRARIES
  for lib in $*; do
    sudo ldconfig -p | grep ${lib} >/dev/null 2>&1 || fatal ${fail_level} ${lib} not installed.
    info lib ${lib} ok
  done
}

step_git_submodules() {
  fail_level=4
  step_info GIT SUBMODULES
  git submodule | while read -r sub_module_line; do
    submodule=$(echo ${sub_module_line} | cut -d \  -f 2)
    if [ -e "./${submodule}/.git" ]; then
      info sub ${submodule} OK
    else
      fatal ${fail_level} submodule ${submodule} missing
    fi
  done
}

step_copy_skel() {
  fail_level=5
  step_info COPY SKEL
  station_volume=${VOLUMES}/${STATION_ID}
  if [ ! -e ${station_volume} ]; then
    cp -a ${SKEL_DIR} ${station_volume} || fatal ${fail_level} copy skel failed
    station_workspace=${station_volume}/workspace
    for repo in ${station_workspace}/*; do
      debug checking repo ${repo}
      dst_repo=${repo}/.git
      if [ ! -d ${dst_repo} ] && [ -e ${dst_repo} ]; then
        repo_name=$(basename ${repo})
        git_dir=${SKEL_DIR}/workspace/${repo_name}/$(cat ${dst_repo} | sed s/gitdir:\ //)

        debug repo is:    ${dst_repo}
        debug git_dir is: ${git_dir}
        
        unlink ${dst_repo}
        cp -a ${git_dir} ${dst_repo}
        sed -i -e "s/worktree =.*/worktree = ../" ${dst_repo}/config
        info initializes REPO: ${dst_repo}

      fi
    done
  else 
    info Not copying skel, as it already exists
  fi
}

step_build_bases() {
  fail_level=6
  step_info BUILD_BASE_IMAGES
  while [ -n "$1" ] && [ -n $"2" ]; do
    container_file=$1; shift
    image_tag=$1; shift
    build_log=./logs/build_base_${image_tag}.log
    podman image build --tag ${image_tag} \
      -f ${container_file} \
      > ${build_log} 2>&1 ||  \
      tail_log ${fail_level} ${build_log} Failed to build ${image_tag}. 
    info Successfully build ${image_tag}
  done
}

step_build_pod() {
  fail_level=7
  step_info BUILD_POD
  project=rdp_station_${STATION_ID}
  build_log=./logs/build_${project}.log
 
  echo buildpod1 
  podman-compose --project-name ${project} build > ${build_log} 2>&1 || \
    tail_log ${fail_level} ${build_log} Failed to build ${project}.
  echo buildpod2
  tail -n 2 ${build_log} | grep Error: && tail_log ${fail_level} ${build_log} Failed to build ${project}.
  info Successfully build ${project}
}

step_restart_pod() {
  fail_level=8
  step_info RESTART_POD
  project=rdp_station_${STATION_ID}
  run_log=./logs/run_${project}.log
  echo restartpod1
  podman-compose --project-name ${project} stop >/dev/null 2>&1 || info ${project} not running.
  podman-compose --project-name ${project} down >/dev/null 2>&1 || info ${project} not up.
  echo restartpod2
  podman pod rm pod_${project} >/dev/null 2>&1 || info pod ${station} not deleted

  echo restartpod3
  podman-compose --in-pod 1 --project-name ${project} up --no-start > ${run_log} 2>&1 || \
    tail_log ${fail_level} ${run_log} Failed to bring up ${project}.
  echo restartpod4
  tail -n 2 ${run_log} | grep Error: && tail_log ${fail_level} ${run_log} Failed to bring up ${project}.
  info Successfully brought ${project} up.

  podman pod start pod_${project} >> ${run_log} 2>&1 || \
    tail_log ${fail_level} ${run_log} Faile to start ${project}
  
  info Successfully started ${project}.
  echo
  info Code is accessable at port ${CODE_PORT}
  info App and api is accessable at port ${BASE_PORT}
}

main $*
