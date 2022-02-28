terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "2.24.1"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "vault" {
  alias = "root"
}

provider "vault" {
  alias     = "customer-success"
  namespace = trimsuffix(module.cs-vault-lob.vault-lob-namespace-id, "/")
}

provider "vault" {
  alias     = "csa"
  namespace = trimsuffix(module.cs-csa-vault-team.vault-team-namespace-id, "/")
}

provider "vault" {
  alias     = "csm"
  namespace = trimsuffix(module.cs-csm-vault-team.vault-team-namespace-id, "/")
}