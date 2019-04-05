#!/bin/bash
set -e

# export KUBECONFIG=~/.kube/kloia

# Extract cluster name from STDIN
eval "$(jq -r '@sh "CLUSTER_NAME=\(.cluster_name)"')"

# Retrieve token with Heptio Authenticator
TOKEN=$(export AWS_DEFAULT_PROFILE=kloia && aws-iam-authenticator token -i $CLUSTER_NAME | jq -r .status.token)

# Output token as JSON
jq -n --arg token "$TOKEN" '{"token": $token}'
