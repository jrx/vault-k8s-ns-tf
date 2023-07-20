# Create Vault Server Auth Service Account

# resource "kubernetes_service_account" "vault-server-auth" {
#     metadata {
#         name        = "vault"
#         namespace   = "default"
#     }
# }
#
# resource "kubernetes_cluster_role_binding" "vault-server-auth" {
#    
#    metadata {
#        name        = "rb-vault-server-auth"
#    }
#
#    role_ref {
#        api_group   = "rbac.authorization.k8s.io"
#        kind        = "ClusterRole"
#        name        = "system:auth-delegator"
#    }
#
#    subject {
#        kind        = "ServiceAccount"
#        name        = "vault"
#        namespace   = var.k8s_namespace
#    }
#}

# Create Vault Agent Auth Service Account

resource "kubernetes_service_account" "vault-agent-auth-janapp" {
  metadata {
    name      = var.k8s_sa_name_jan_app
    namespace = var.k8s_namespace
  }
}

resource "kubernetes_service_account" "vault-agent-auth-saraapp" {
  metadata {
    name      = var.k8s_sa_name_sara_app
    namespace = var.k8s_namespace
  }
}