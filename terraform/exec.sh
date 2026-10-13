#!/bin/bash

function export_env_vars() {
    while IFS='=' read -r key value; do
        # Skip empty lines and comments (lines starting with #)
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        key=$(echo "$key" | xargs)

        value="${value%\"}"  # Remove trailing quote
        value="${value#\"}"  # Remove leading quote

        export "TF_VAR_${key}=${value}"
    done <$1
}

function export_json_vars() {
    while IFS= read -r entry; do
        key=$(jq -r '.key' <<<"$entry")
        value=$(jq -r '.value | if type == "string" then . else tojson end' <<<"$entry")
        export "TF_VAR_${key}=${value}"
    done < <(jq -c 'to_entries[]' "$1")
}

home_stack_dir=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/..
repo_path="/build/git/home-stack"
tf_envs_path="${repo_path}/terraform/environments"
export TF_VAR_vars_path="${repo_path}/vars"

set -o errexit -o errtrace -o pipefail

handle_error() {
    echo "An error occurred. Exiting..."
    exit 1
}

trap handle_error ERR

# Parse environment and map to root module
case $1 in
common | Common | COMMON)
    var_env="common"
    ;;
dev | Dev | DEV)
    var_env="development"
    ;;
prod | Prod | PROD)
    var_env="production"
    ;;
*)
    echo "$1 is not valid" 1>&2
    return
    ;;
esac

git -C "${home_stack_dir}" pull
# export TF_LOG=DEBUG

# Since the variable files may contain variables not used by Terraform, TF_VAR_* environment variables
# are used, instead of passing the file file to '-var-file' in the terraform command later,
# to avoid warnings about undeclared varialbes.
export_env_vars ${TF_VAR_vars_path}/secrets.env
export_json_vars ${TF_VAR_vars_path}/common.config.json
export_json_vars ${TF_VAR_vars_path}/${var_env}.config.json

terraform -chdir="$tf_envs_path/${var_env}" $2 "${@:3}"
