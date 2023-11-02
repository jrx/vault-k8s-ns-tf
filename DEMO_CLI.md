
# Demo for creating an example app via Vault CLI

## Create Kubernetes SA

```sh
kubectl create sa vault-agent-auth-adrianapp -n apps
kubectl get sa -n apps
```

## Create Vault Role

```sh
vault write -namespace="sea" auth/kubernetes/role/adrianapp-role \
    bound_service_account_names="vault-agent-auth-adrianapp" \
    bound_service_account_namespaces="apps" \
    policies=sea-secret-policy \
    ttl=3600

vault policy read -namespace="sea" sea-secret-policy
```

## Create Vault Entity

```sh
vault write -namespace="sea" -format=json identity/entity \
  name="adrianapp" \
  metadata=AppName="adrianapp" \
  metadata=Environment="dev" \
  metadata=LobName="sea" \
  metadata=TeamName="sa" \
  | jq -r ".data.id" > /tmp/entity_id.txt

vault auth list -namespace="sea" -format=json \
  | jq -r '.["kubernetes/"].accessor' \
  > /tmp/accessor_k8s.txt
```

## Create Vault Entity Alias

```sh
kubectl get serviceaccount vault-agent-auth-adrianapp -n apps -o json | jq -r  .metadata.uid > /tmp/uid_k8s.txt

vault write -namespace="sea" identity/entity-alias \
  name=$(cat /tmp/uid_k8s.txt) \
  canonical_id=$(cat /tmp/entity_id.txt) \
  mount_accessor=$(cat /tmp/accessor_k8s.txt)
```

## Assign Vault App Policy within the SA namespace

```sh
vault write -namespace="sea" -format=json identity/entity/id/$(cat /tmp/entity_id.txt) \
  policies="sa-app-secret-policy"

vault policy read -namespace="sea/sa" sa-app-secret-policy
```

## Assign Vault Entity to the SA Group

```sh
vault read -namespace="sea/sa" identity/group/name/sa-group -format=json \
  |  jq -r '.data.id' \
  > /tmp/group_id.txt

vault read -namespace="sea/sa" -field="member_entity_ids" identity/group/name/sa-group \
  > /tmp/member_entity_ids.txt

vault write -namespace="sea/sa" /identity/group/id/$(cat /tmp/group_id.txt) \
  member_entity_ids="$(cat /tmp/entity_id.txt),$(cat /tmp/member_entity_ids.txt | sed 's/\[//g' | sed 's/\]//g' | tr ' ' ',')"

# verify
vault read -namespace="sea/sa" identity/group/name/sa-group -format=json
```

## Create a Secret

```sh
vault kv put -namespace="sea/sa" -mount="secret" sa-app-secrets/adrianapp \
  value="Only the adrianapp app should see this"
```

## Deploy Kubernetes App

```yaml
cat <<EOF > /tmp/vault-agent-adrianapp.yaml
apiVersion: v1
kind: ConfigMap
data:
  nginx.conf: |
    server {
            listen 80 default_server;

            root /usr/share/nginx/html;
            index index.html;

            server_name my-website.com;

            location / {
                    try_files \$uri \$uri/ =404;
            }
    }
metadata:
  name: nginxconfigmap
---
apiVersion: v1
kind: Service
metadata:
  name: vault-agent-adrianapp
  labels:
    run: vault-agent-adrianapp
spec:
  type: NodePort
  selector:
    run: vault-agent-adrianapp
  ports:
    - port: 80
      targetPort: 80
      # Optional field
      # By default and for convenience, the Kubernetes control plane will allocate a port from a range (default: 30000-32767)
      nodePort: 32100
      name: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-agent-adrianapp
spec:
  selector:
    matchLabels:
      run: vault-agent-adrianapp
  replicas: 2
  template:
    metadata:
      labels:
        run: vault-agent-adrianapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "adrianapp-role"
        vault.hashicorp.com/tls-skip-verify: "true"
        vault.hashicorp.com/agent-run-as-same-user: "true"
        vault.hashicorp.com/agent-set-security-context: "true"
        vault.hashicorp.com/agent-cache-enable: "true"
        vault.hashicorp.com/namespace: "sea"
        # Static secret as index.html
        vault.hashicorp.com/secret-volume-path-sea.html: "/usr/share/nginx/html"
        vault.hashicorp.com/agent-inject-secret-sea.html: "secret/sea"
        vault.hashicorp.com/agent-inject-template-sea.html: |
          {{- with secret "secret/sea" -}}
          {{ .Data.value }}
          {{- end }}
        # Static secret as sa.html
        vault.hashicorp.com/secret-volume-path-sa.html: "/usr/share/nginx/html"
        vault.hashicorp.com/agent-inject-secret-sa.html: "sa/secret/sa-team-secret"
        vault.hashicorp.com/agent-inject-template-sa.html: |
          {{- with secret "sa/secret/sa-team-secret" -}}
          {{ .Data.value }}
          {{- end }}
        # Static secret as adrianapp.html
        vault.hashicorp.com/secret-volume-path-adrianapp.html: "/usr/share/nginx/html"
        vault.hashicorp.com/agent-inject-secret-adrianapp.html: "sa/secret/sa-app-secrets/adrianapp"
        vault.hashicorp.com/agent-inject-template-adrianapp.html: |
          {{- with secret "sa/secret/sa-app-secrets/adrianapp" -}}
          {{ .Data.value }}
          {{- end }}
    spec:
      volumes:
      - name: configmap-volume
        configMap:
          name: nginxconfigmap
      securityContext:
        sysctls:
        - name: net.ipv4.ip_unprivileged_port_start
          value: "80"
      containers:
      - name: nginx
        image: nginxinc/nginx-unprivileged
        securityContext:
          runAsUser: 1000570000
          runAsGroup: 1000
        ports:
          - containerPort: 80
        resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "500m"
        livenessProbe:
          httpGet:
            path: /sea.html
            port: 80
          initialDelaySeconds: 30
          timeoutSeconds: 1
        volumeMounts:
        - mountPath: /etc/nginx/conf.d
          name: configmap-volume
      shareProcessNamespace: true
      serviceAccountName: vault-agent-auth-adrianapp
---
EOF
```

```sh
kubectl apply -f /tmp/vault-agent-adrianapp.yaml -n apps

kubectl port-forward service/vault-agent-adrianapp 8100:80 -n apps

curl http://localhost:8100/sea.html
curl http://localhost:8100/sa.html
curl http://localhost:8100/adrianapp.html
```

## Testing

### Reset

```sh
kubectl delete -f /tmp/vault-agent-adrianapp.yaml -n apps
kubectl delete sa vault-agent-auth-adrianapp -n apps
```

### Redeploy with new SA UID

```sh
kubectl create sa vault-agent-auth-adrianapp -n apps
kubectl get sa -n apps

# Fails
#kubectl apply -f /tmp/vault-agent-adrianapp.yaml -n apps
#kubectl get pods -n apps
#kubectl logs vault-agent-adrianapp-8b5fd6bd-c9fwn -n apps -c vault-agent-init

# Delete old Entity Alias
OLD_ENTITY_ALIAS=$(vault read -namespace="sea" identity/entity/id/$(cat /tmp/entity_id.txt) -format=json | jq -r '.data.aliases[0].id')
vault delete -namespace="sea" identity/entity-alias/id/$OLD_ENTITY_ALIAS

# Register new SA UID
kubectl get serviceaccount vault-agent-auth-adrianapp -n apps -o json | jq -r  .metadata.uid > /tmp/uid_k8s.txt

# Set new Entity Alias
vault write -namespace="sea" identity/entity-alias \
  name=$(cat /tmp/uid_k8s.txt) \
  canonical_id=$(cat /tmp/entity_id.txt) \
  mount_accessor=$(cat /tmp/accessor_k8s.txt)

# Succeeds
kubectl apply -f /tmp/vault-agent-adrianapp.yaml -n apps
kubectl get pods -n apps
```
