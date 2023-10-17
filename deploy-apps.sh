#!/bin/sh

# Apply vault-agent demo configurations
kubectl apply -f configs/vault-agent-janapp.yaml -n apps
kubectl apply -f configs/vault-agent-saraapp.yaml -n apps