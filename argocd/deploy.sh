#!/bin/bash

# Step 1: Generate JSON from Jsonnet
jsonnet -J ../libs manifest.jsonnet -o manifest.json

# Step 2: Convert JSON to YAML
yq -y < manifest.json > manifest.yaml

# Step 3: Create the namespace if it doesn't exist
kubectl get namespace argocd-mockup >/dev/null 2>&1 || kubectl create namespace argocd-mockup

# Optional: Display the generated YAML for verification
cat manifest.yaml

# Step 4: Apply the generated YAML to Kubernetes
kubectl apply -f manifest.yaml
