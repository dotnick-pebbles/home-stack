#!/bin/bash
main() {
  set -o errexit -o errtrace

  handle_error() {
    print_error "An error occurred. Exiting..."
    exit 1
  }

  trap handle_error ERR

  load_configuration

  print_header "Setting up pool and storage"
  if ! pvesh get "/storage/${storage_name}" >/dev/null 2>&1; then
    print_info "Creating storage '${storage_name}'"
    pvesm add dir ${storage_name} \
      --path /var/lib/vz/home_stack \
      --content rootdir,import,snippets,vztmpl,images
  else
    print_warning "Storage '${storage_name}' already exists"
  fi

  if ! pvesh get /pools --poolid "${pool_id}" >/dev/null 2>&1; then
    print_info "Creating pool '${pool_id}'"
    pveum pool add "${pool_id}"
    print_info "Adding ${storage_name} to pool"
    pveum pool modify ${pool_id} --storage ${storage_name}
  else
    print_warning "Pool '${pool_id}' already exists"
  fi

  print_header "Setting up user and permissions"
  if ! pvesh get "/access/users/${user_id}" >/dev/null 2>&1; then
    print_info "Creating user '${user_id}'"
    pveum user add ${user_id}
  else
    print_warning "User '${user_id}' already exists"
  fi

  if ! pvesh get "/access/users/${user_id}/token/${token_id}" >/dev/null 2>&1; then
    print_info "Creating api token '${token_id}' for '${user_name}'"
    token_output=$(pveum user token add ${user_id} ${token_id} 2>&1)
    token_secret=$(echo "$token_output" | tr -d ' ' | tr -d '│' | grep -oE 'value[^ ]+' | sed 's/value//')
    token_secret_file_name=".${token_id}_secret"
    printf $token_secret >$token_secret_file_name
    print_warning "Token secret saved to ${token_secret_file_name}"
  else
    print_warning "Token '${token_id}' already exists"
  fi

  if ! pvesh get /access/roles/${role_id} >/dev/null 2>&1; then
    print_info "Creating role '${pool_id}'"
    pveum role add ${role_id} --privs "Sys.AccessNetwork,SDN.Use"
  else
    print_warning "Role '${role_id}' already exists"
  fi

  print_info "Assigning permissions"
  pveum acl modify "/pool/${pool_id}" --roles Administrator --tokens "${user_id}!${token_id}" --users "${user_id}"
  pveum acl modify "/" --roles ${role_id} --tokens "${user_id}!${token_id}" --users "${user_id}"

  print_header "Downloading lxc tempalte '${template_name}'"
  pveam update
  pveam download ${storage_name} ${template_name}

  print_header "Creating container ${build_host_id} '${build_host_hostname}'"
  if pct status "$build_host_id" >/dev/null 2>&1; then
    print_warning "Container $build_host_id already exists on node '${build_host_hostname}'"
  else
    pct create ${build_host_id} ${storage_name}:vztmpl/${template_name} \
      --pool ${pool_id} \
      --hostname ${build_host_hostname} \
      --cores 1 --memory 2048 --swap 512 \
      --rootfs ${storage_name}:12 \
      --net0 name=eth0,bridge=vmbr0,ip=${build_host_ip}/24,gw=${gateway},firewall=1 \
      --unprivileged 1 \
      --features nesting=1 \
      --onboot 1 \
      --start 1
  fi

  pct_exec "install -m 400 /dev/null ${build_host_env_location}"

  print_info "Setting up SSH keys"
  setup_keys

  print_header "Installing Terraform"
  print_info "Installing prerequisites"
  pct_exec apt-get update
  pct_exec apt-get install --yes gnupg git jq

  print_info "Installing private key"
  pct_exec "wget -O- https://apt.releases.hashicorp.com/gpg |
    gpg --dearmor |
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null"
  pct_exec '. /etc/os-release && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${UBUNTU_CODENAME:-$VERSION_CODENAME} main" |
    tee /etc/apt/sources.list.d/hashicorp.list'

  print_info "Installing terraform"
  pct_exec apt-get update
  pct_exec apt-get install --yes terraform

  print_header "Cloning Repo"
  pct_exec mkdir -p ${git_path}
  pct_exec "if cd ${repo_path}; then git pull; else git clone https://github.com/dotnick-pebbles/home-stack ${repo_path}; fi"

  print_header "Setting up aliases"
  pct_exec "echo HOME_STACK_PATH=${repo_path} >> ${build_host_env_location}"
  pct_exec "grep -q \"The following is used by home-stack\" ~/.bashrc && \
    sed -i '/#### The following is used by home-stack/,/#### end of home-stack/d' ~/.bashrc ; \
    cat >> ~/.bashrc << 'EOF'
#### The following is used by home-stack. Do not modify
source ${repo_path}/bootstrap/home-stack.bashrc
#### end of home-stack
EOF"

  print_header "All done"
}

load_configuration() {
  header="\033[0;92m"
  debug="\033[0;96m"
  info="\033[0;94m"
  warning="\033[0;93m"
  error="\033[0;91m"
  reset="\033[0m"

  build_host_env_location='$HOME/.p.env'
  build_host_ssh_type=ed25519
  build_host_ssh_path='$HOME/.ssh'
  build_host_ssh_file_name='$(hostname)__$(echo $USER)__id_'${build_host_ssh_type}

  additional_host_ssh_keys_path=additional_ssh_keys
  config_file=common.config.json

  if [ -f ${config_file} ]; then
    config_objects=".host_settings,.build_server"
    while IFS=$'\t' read -r key value; do
      printf -v "$key" '%s' "$value"
    done < <(jq -r "${config_objects} | to_entries[] | [.key, .value] | @tsv" "$config_file")
  else
    print_error "Could not find '${config_file}'"
    exit 1
  fi
}

setup_keys() {
  expanded_path=$(pct_exec "sh -c 'echo ${build_host_ssh_path}/${build_host_ssh_file_name}'")
  password=$(openssl rand -base64 32)
  if pct_exec "test -f ${expanded_path}"; then
    print_warning "Skipping key creation. '$expanded_path' already exists on build host. Overwriting will require redeploying all systems that rely on the existing key."
  else
    print_info "Creating SSH keys."
    pct_exec ssh-keygen \
      -t ${build_host_ssh_type} \
      -f ${expanded_path} \
      -N ${password} \
      -q

    pct_exec "cat <<EOT >> ${build_host_env_location}
SSH_PASS=${password}
SSH_FILE_PATH=${expanded_path}
EOT"
  fi

  additional_files=$(
    shopt -s nullglob dotglob
    echo ${additional_host_ssh_keys_path}/*.pub
  )

  if ((${#additional_files})); then
    print_info "Copying additional public keys found in ${additional_host_ssh_keys_path}"
    pct_exec "mkdir -p ${additional_ssh_keys_path}"
    for file in ${additional_files}; do
      pct push ${build_host_id} ${file} "${additional_ssh_keys_path}/$(basename $file)"
    done
  fi

  pct_exec "mkdir -p ${authorized_ssh_keys_path} && cp ${build_host_ssh_path}/${build_host_ssh_file_name}.pub ${authorized_ssh_keys_path}"
}

print_message() {
  echo -e "$2$1${reset}"
}

print_info() {
  print_message "$1" "${info}"
}

print_warning() {
  print_message "$1" "${warning}"
}

print_error() {
  print_message "$1" "${error}"
}

print_header() {
  printf -v header_text '#%.0s' $(seq 1 $(tput cols))
  print_message "${header_text}" ${header}
  print_message "$1" ${header}
  print_message "${header_text}" ${header}
}

pct_exec() {
  pct exec ${build_host_id} -- sh -c "$*"
}

main
