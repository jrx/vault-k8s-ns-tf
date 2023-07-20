#!/bin/sh

# Apply vault-agent demo configurations

kubectl apply -f configs/vault-agent-janapp.yaml
kubectl apply -f configs/vault-agent-saraapp.yaml

echo ""
echo "JanApp Minikube Service URL:"

minikube service --url vault-agent-janapp

echo ""
echo "SaraApp Minikube Service URL:"

minikube service --url vault-agent-saraapp