#!/usr/bin/env bash
DEBUG_LEVELS="ERROR WARNING INFO"
get_room() {
  room=$1; shift
  cat $(echo $0 | sed s/.sh/.csv/) | sed -e "s/ *//g" | grep ${room},
}
start_room() {
  room=$1; shift
  for room_nr in  $(get_room ${room} | cut -d , -f 3 ); do
    $(dirname $0)/../run.sh ${room_nr} 
  done
}
stop_room() {
  room=$1; shift
  for room_nr in  $(get_room ${room} | cut -d , -f 3 ); do
    pod_name=pod_rdp_station_${room_nr}
    info stopping ${pod_name}
    podman pod stop ${pod_name}
    podman pod rm ${pod_name}
  done
}
generate_room() {
  room=$1; shift
  TEMPLATE=${SCRIPT_DIR}/room.nixos.nginx.template.nix
  
  cat ${TEMPLATE} | grep -F '# HEAD' | sed -e 's/# HEAD//'
  for workstation_line in $(get_room ${room}); do
    workstation_domain=$(echo ${workstation_line} | cut -d , -f 2)
    domain=$(echo ${workstation_domain}  | sed -e "s/.*\.//")
    workstation=$(echo ${workstation_domain} | sed -e "s/\.${domain}//")
    pod_number=$(echo ${workstation_line} | cut -d , -f 3)
    code_port=$(( pod_number*5+8001 ))
    app_port=$(( pod_number*5+8000 ))
    grep -F '# MAIN' ${TEMPLATE} | sed -e 's/# MAIN//' | sed -e s/HOST/${workstation}-code.${domain}/ | sed s/PORT/${code_port}/
    grep -F '# MAIN' ${TEMPLATE} | sed -e 's/# MAIN//' | sed -e s/HOST/${workstation}-app.${domain}/ | sed s/PORT/${app_port}/
  done
  cat ${TEMPLATE} | grep -F '# FOOT' | sed -e 's/# FOOT//'
}
main() {
  cmd=$1;  shift; [ -z "${cmd}"  ] && usage
  room=$1; shift; [ -z "${room}" ] && usage
  debug "ROOM: ${room}"
  debug "CMD: ${cmd}"
  case ${cmd} in 
    start)
      info starting room ${room}
      start_room ${room}
      ;;
    stop)
      info stopping room ${room}
      stop_room ${room}
      ;;
    status)
      info checking status of room ${room} 
      ;;
    generate)
      info generating nixos nginx config of room ${room}
      generate_room ${room}
      ;;
    *)
      error "unknown command ${cmd}"
      usage
      ;;
  esac 
}
log() {
    level=$1
    shift
    for i in ${DEBUG_LEVELS} CRITICAL; do
      [ ${i} == ${level} ] && printf "%-8s %s %s\n" ${level} $(date +%Y%m%d-%H:%M:%S) "$*" >&2
    done
}
error() {
  log ERROR $*
}
warning() {
  log WARNING $*
}
info() {
  log INFO $*
}
debug() {
  log DEBUG $*
}
critical() {
  exit_code=$1
  shift
  log CRITICAL $*
  exit ${exit_code}
}
usage() {
  critical 1 "$(basename $0) <cmd> <room>" 
}

SCRIPT_DIR=$(cd $(dirname $0); pwd)
main $*
