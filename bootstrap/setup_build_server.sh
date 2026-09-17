#!/bin/bash
home_stack_dir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/..

for env_file in ${home_stack_dir}/env/hosts.env ${home_stack_dir}/bootstrap/bootstrap.env; do
  if [ -f ${env_file} ]; then
    source ${env_file}
  else
    echo "Could not find '${env_file}'"
    exit 1
  fi
done

# Download Debian lxc tempalte
pveam update
pveam download ${storage_name} ${template_name}

# Create container
pct create ${build_host_id} ${storage_name}:vztmpl/${template_name} \
  --hostname home-builder \
  --cores 1 --memory 2048 --swap 512 \
  --rootfs local-lvm:12 \
  --net0 name=eth0,bridge=vmbr0,ip=${ip}/24,gw=${gateway},firewall=1 \
  --unprivileged 1 \
  --password ${password} \
  --features nesting=1 \
  --onboot 1 \
  --start 1
