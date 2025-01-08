#!/bin/bash

# Step 1: Generate JSON from Jsonnet
jsonnet -J ../libs apps.jsonnet -o apps.json

# Step 2: Convert JSON to plain text
jq -c '.[]' apps.json > apps_plain.txt

# Step 3: Convert each JSON object to YAML and add document separators
while read -r item; do
  echo "$item" | yq -y
  echo "---"
done < apps_plain.txt > apps.yaml

# Step 4: Apply the generated YAML to Kubernetes
kubectl apply -f apps.yaml
