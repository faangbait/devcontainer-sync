#!/bin/bash
set -euo pipefail

mkdir -p "$HOME/.aws" "$HOME/.bashrc.d"

cat > "$HOME/.aws/config" <<'AWS_CONFIG'
[default]
region = us-east-1
output = json
sso_session = example-sso
sso_account_id = 123456789012
sso_role_name = AdministratorAccess

[sso-session example-sso]
sso_start_url = https://example.awsapps.com/start/#
sso_region = us-east-1
sso_registration_scopes = sso:account:access
AWS_CONFIG

cat > "$HOME/.bashrc.d/aws-sso-login.sh" <<'AWS_HOOK'
aws() {
  local argument index
  local -a profile_args=()

  for ((index = 1; index <= $#; index++)); do
    argument="${!index}"
    case "$argument" in
      --profile)
        if ((index == $#)); then
          command aws "$@"
          return
        fi
        index=$((index + 1))
        profile_args=(--profile "${!index}")
        ;;
      --profile=*)
        profile_args=("$argument")
        ;;
    esac
  done

  case " $* " in
    *" sso login "*|*" sso logout "*|*" configure "*|*" --help "*|*" --version "*)
      command aws "$@"
      return
      ;;
  esac

  if ! command aws "${profile_args[@]}" sts get-caller-identity >/dev/null 2>&1; then
    command aws "${profile_args[@]}" sso login
  fi

  command aws "$@"
}
AWS_HOOK

bashrc_hook="source \"$HOME/.bashrc.d/aws-sso-login.sh\""
touch "$HOME/.bashrc"
grep -qxF "$bashrc_hook" "$HOME/.bashrc" || printf '\n%s\n' "$bashrc_hook" >> "$HOME/.bashrc"
