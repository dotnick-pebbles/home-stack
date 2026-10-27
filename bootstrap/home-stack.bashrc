var_path=${HOME_STACK_VARS_PATH:-/build/vars/home-stack}
repo_path=${HOME_STACK_REPO_PATH:-/build/git/home-stack}

# SSH
build_host_ssh_type=ed25519
build_host_ssh_path='$HOME/.ssh'
build_host_ssh_file_name="$HOSTNAME__$USER__id_${build_host_ssh_type}"

if [ -z "$SSH_AUTH_SOCK" ]; then
    before=$(compgen -v)

    source $HOME/.p.env
    eval $(ssh-agent -s)
    DISPLAY=1 SSH_ASKPASS="${HOME_STACK_PATH}/bootstrap/askpass.sh" ssh-add ${SSH_FILE_PATH} </dev/null

    after=$(compgen -v)
    newly_added=$(comm -13 <(echo "$before" | sort) <(echo "$after" | sort))
    for var in $newly_added; do
        unset "$var"
    done
fi

# Terraform
invoke_terraofrm_exec_sh='${repo_path}/terraform/exec.sh -v ${var_path}'

for environment in "common" "dev" "prod"; do
    for action in "console" "init" "plan" "apply" "destroy"; do
        alias tf-${action}-${environment}="${invoke_terraofrm_exec_sh} -e ${environment} -a ${action}" $3
    done
done
