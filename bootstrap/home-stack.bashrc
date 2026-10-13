# SSH
build_host_ssh_type=ed25519
build_host_ssh_path='$HOME/.ssh'
build_host_ssh_file_name="$HOSTNAME__$USER__id_${build_host_ssh_type}"

if [ -z "$SSH_AUTH_SOCK" ]; then
    before=$(compgen -v)

    source .p.env
    eval $(ssh-agent -s)
    DISPLAY=1 SSH_ASKPASS="${HOME_STACK_PATH}/bootstrap/askpass.sh" ssh-add ${SSH_FILE_PATH} </dev/null

    after=$(compgen -v)
    newly_added=$(comm -13 <(echo "$before" | sort) <(echo "$after" | sort))
    for var in $newly_added; do
        unset "$var"
    done
fi

# Terraform
invoke_exec_sh='/build/git/home-stack/terraform/exec.sh'

alias tf-init-common="${invoke_exec_sh} common init"
alias tf-plan-common="${invoke_exec_sh} common plan"
alias tf-apply-common="${invoke_exec_sh} common apply -auto-approve"
alias tf-destroy-common="${invoke_exec_sh} common destroy -auto-approve"

alias tf-init-dev="${invoke_exec_sh} dev init"
alias tf-plan-dev="${invoke_exec_sh} dev plan"
alias tf-apply-dev="${invoke_exec_sh} dev apply -auto-approve"
alias tf-destroy-dev="${invoke_exec_sh} dev destroy -auto-approve"

alias tf-init-prod="${invoke_exec_sh} prod init"
alias tf-plan-prod="${invoke_exec_sh} prod plan"
alias tf-apply-prod="${invoke_exec_sh} prod apply -auto-approve"
alias tf-destroy-prod="${invoke_exec_sh} prod destroy -auto-approve"
