#!/bin/bash
function export_env_vars() {
    while IFS='=' read -r key value; do
        # Skip empty lines and comments (lines starting with #)
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        key=$(echo "$key" | xargs)

        value="${value%\"}" # Remove trailing quote
        value="${value#\"}" # Remove leading quote

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

while getopts 'a:e:v:s:l:p' OPTION; do
    case "$OPTION" in
    a) action="$OPTARG" ;;
    e) environment="$OPTARG" ;;
    v) vars_path="$OPTARG" ;;
    s) sub_args="$OPTARG" ;;
    l) log_level="$OPTARG" ;;
    p) auto_approve="-auto-approve" ;;
    ?)
        echo "Invalid flag provided"
        exit 1
        ;;
    esac
done
shift "$(($OPTIND - 1))"

repo_path=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/..
tf_envs_path="${repo_path}/terraform/environments"
export TF_VAR_vars_path=${vars_path}

set -o errexit -o errtrace -o pipefail

handle_error() {
    echo "An error occurred. Exiting..."
    exit 1
}

trap handle_error ERR

# Parse environment and map to root module
case ${environment} in
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
    echo "${environment} is not a valid environment" 1>&2
    false
    ;;
esac

git -C "${repo_path}" pull
export TF_LOG=${log_level:-}
state_path=$TF_DATA_DIR/state

# Since the variable files may contain variables not used by Terraform, TF_VAR_* environment variables
# are used, instead of passing the file file to '-var-file' in the terraform command later,
# to avoid warnings about undeclared varialbes.
export_env_vars ${vars_path}/secrets.env
export_json_vars ${vars_path}/common.config.json
export_json_vars ${vars_path}/${var_env}.config.json

terraform -chdir="$tf_envs_path/${var_env}" ${action} ${auto_approve} ${sub_args} ${arguments}
