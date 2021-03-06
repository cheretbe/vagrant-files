#!/bin/bash

env_var_names=( "AO_DEFAULT_GITHUB_USER" "AO_DEFAULT_GITHUB_TOKEN"
  "AO_DEFAULT_GITHUB_EMAIL" "AO_DEFAULT_GITLAB_USER" "AO_DEFAULT_GITLAB_EMAIL"
  "AO_DEFAULT_GITLAB_PASSWORD" "AO_CHOCO_SERVER_API_TOKEN" "AO_PUBLISH_SSH_PORT"
)

output_lines=()

for env_var in "${env_var_names[@]}"
do
  if ! [ -z ${!env_var+x} ]; then
    output_lines+=( "${env_var}=${!env_var}" )
  fi
done

mkdir -p "$(dirname "$1")"
printf "%s\r\n" "${output_lines[@]}" >"$1"