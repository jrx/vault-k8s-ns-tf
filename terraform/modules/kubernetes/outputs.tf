# output "vault-server-auth-secret-name" {
#     value = kubernetes_service_account.vault-server-auth.default_secret_name
# }

output "k8s-sa-janapp-uid" {
  value = kubernetes_service_account.vault-agent-auth-janapp.metadata[0].uid
}

output "k8s-sa-saraapp-uid" {
  value = kubernetes_service_account.vault-agent-auth-saraapp.metadata[0].uid
}