# Create Vault Agent Auth Service Account

resource "kubernetes_namespace" "k8s_namespace" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "kubernetes_service_account" "vault-agent-auth-janapp" {
  metadata {
    name      = var.k8s_sa_name_jan_app
    namespace = kubernetes_namespace.k8s_namespace.id
  }
}

resource "kubernetes_service_account" "vault-agent-auth-saraapp" {
  metadata {
    name      = var.k8s_sa_name_sara_app
    namespace = kubernetes_namespace.k8s_namespace.id
  }
}