#!/bin/bash
function main() {
  set -o errexit -o errtrace

  handle_error() {
    print_error "An error occurred. Exiting..."
    exit 1
  }

  trap handle_error ERR

  home_stack_dir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/..

  env_files=(
    "${home_stack_dir}/vars/hosts.env"
    "${home_stack_dir}/bootstrap/bootstrap.env"
  )

  for env_file in ${env_files[@]}; do
    if [ -f ${env_file} ]; then
      source ${env_file}
    else
      print_error "Could not find '${env_file}'"
      exit 1
    fi
  done

  print_header "Downloading lxc tempalte '${template_name}'"
  pveam update
  pveam download ${storage_name} ${template_name}

  print_header "Creating container ${id} '${hostname}'"
  if pct status "$build_host_id" >/dev/null 2>&1; then
    print_info "Container $build_host_id already exists on node '${hostname}'"
  else
    pct create ${build_host_id} ${storage_name}:vztmpl/${template_name} \
      --hostname ${hostname} \
      --cores 1 --memory 2048 --swap 512 \
      --rootfs local-lvm:12 \
      --net0 name=eth0,bridge=vmbr0,ip=${ip}/24,gw=${gateway},firewall=1 \
      --unprivileged 1 \
      --password ${password} \
      --features nesting=1 \
      --onboot 1 \
      --start 1
  fi

  print_header "Installing Terraform"
  print_info "Installing prerequisites"
  exec apt-get update
  exec apt-get install --yes gnupg lsb-release git

  print_info "Installing private key"
  exec "wget -O- https://apt.releases.hashicorp.com/gpg |
    gpg --dearmor |
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null"
  exec "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main\" |
    tee /etc/apt/sources.list.d/hashicorp.list"

  print_info "Installing terraform"
  exec apt-get update
  exec apt-get install --yes terraform

  print_header "Cloning Repo"
  exec mkdir -p git
  exec git clone https://github.com/dotnick-pebbles/home-stack git

  print_header "All done"
}

function print_message() {
  echo -e "$2$1${reset}"
}
function print_info() {
  print_message "$1" "${info}"
}
function print_info() {
  print_message "$1" "${info}"
}
function print_error() {
  print_message "$1" "${error}"
}
function print_header() {
  printf -v header_text '#%.0s' $(seq 1 $(tput cols))
  print_message "${header_text}" ${header}
  print_message "$1" ${header}
  print_message "${header_text}" ${header}
}
function exec() {
  echo $*
  pct exec ${build_host_id} -- sh -c "$*"
}

main
