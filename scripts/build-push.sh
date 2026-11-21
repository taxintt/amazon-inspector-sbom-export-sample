#!/bin/sh
# Run after terraform apply. Builds the images under images/ and pushes them to the ECR repositories of the same name
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
urls="$(terraform -chdir="$root/terraform" output -json ecr_repository_urls)"
registry="$(echo "$urls" | jq -r 'to_entries[0].value | split("/")[0]')"
region="$(terraform -chdir="$root/terraform" output -raw region)"

password="$(aws ecr get-login-password --region "$region")"
echo "$password" | docker login --username AWS --password-stdin "$registry"

for name in $(echo "$urls" | jq -r 'keys[]'); do
  url="$(echo "$urls" | jq -r --arg n "$name" '.[$n]')"
  docker build --platform linux/amd64 -t "$url:latest" "$root/images/$name"
  docker push "$url:latest"
done
