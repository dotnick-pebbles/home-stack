#!/bin/bash
function print_message() {
  echo -e "$2$1${reset}"
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

home_stack_dir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/..

env_files=(
  "${home_stack_dir}/env/hosts.env"
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

print_header "Installing Terraform"
print_info "Installing prerequisites"
pct exec ${build_host_id} -- apt-get update
pct exec ${build_host_id} -- apt-get install --yes gnupg lsb-release

print_info "Installing private key"
pct exec ${build_host_id} -- sh -c "wget -O- https://apt.releases.hashicorp.com/gpg |
  gpg --dearmor |
  tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null"
pct exec ${build_host_id} -- sh -c "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main'
 | tee /etc/apt/sources.list.d/hashicorp.list"

print_info "Installing terraform"
pct exec ${build_host_id} -- apt-get update
pct exec ${build_host_id} -- apt-get install --yes terraform
