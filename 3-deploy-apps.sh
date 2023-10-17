#!/bin/sh

# Apply vault-agent demo configurations
kubectl create namespace apps

kubectl apply -f configs/vault-agent-janapp.yaml -n apps
kubectl apply -f configs/vault-agent-saraapp.yaml -n apps