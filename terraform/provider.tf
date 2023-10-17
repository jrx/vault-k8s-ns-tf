terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }

    vault = {
      source = "hashicorp/vault"
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
  alias     = "sea"
  namespace = trimsuffix(module.cs-vault-lob.vault-lob-namespace-id, "/")
}

provider "vault" {
  alias     = "sa"
  namespace = trimsuffix(module.cs-sa-vault-team.vault-team-namespace-id, "/")
}

provider "vault" {
  alias     = "se"
  namespace = trimsuffix(module.cs-se-vault-team.vault-team-namespace-id, "/")
}