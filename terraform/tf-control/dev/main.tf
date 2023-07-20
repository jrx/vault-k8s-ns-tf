# Create K8s Service Accounts

module "tf-k8s" {
  source = "../../modules/tf-k8s"

  k8s_sa_name_jan_app  = var.k8s_sa_name_jan_app
  k8s_sa_name_sara_app = var.k8s_sa_name_sara_app
  k8s_namespace        = var.k8s_namespace
}

# Create Customer Success LOB - we have a K8s cluster per LOB in this scenario.
# There are some LOB secrets that need to be accessed by lower-level OUs here, 
# as well as within those lower-level OU namespaces themselves

module "cs-vault-lob" {
  source = "../../modules/tf-vault-lob"

  providers = {
    vault.root = vault.root
    vault.lob  = vault.sea
  }

  lob_name             = var.lob_sea
  lob_group_member_ids = [module.cs-sa-vault-team.vault-team-group-id]

  k8s_host   = var.k8s_host
  k8s_issuer = var.k8s_issuer
  k8s_token  = var.k8s_token
  k8s_ca     = var.k8s_ca

  # vault_server_sa_secret_name = module.tf-k8s.vault-server-auth-secret-name
}

module "cs-sa-vault-team" {
  source = "../../modules/tf-vault-team"
  providers = {
    vault.lob  = vault.sea
    vault.team = vault.sa
  }

  lob_name              = var.lob_sea
  team_name             = var.team_sa
  team_group_member_ids = [module.cs-sa-jan-vault-app.app-entity-id, module.cs-sa-sara-vault-app.app-entity-id]

}

module "cs-sa-jan-vault-app" {
  source = "../../modules/tf-vault-app"
  providers = {
    vault.lob  = vault.sea
    vault.team = vault.sa
  }

  app_name = var.app_name_janapp
  lob_name = var.lob_sea

  team_name                     = var.team_sa
  team_secret_mount_accessor_id = module.cs-sa-vault-team.vault-team-secret-mount-accessor

  kubernetes_auth_backend_path           = module.cs-vault-lob.vault-lob-k8s-auth-backend-path
  kubernetes_auth_backend_mount_accessor = module.cs-vault-lob.vault-lob-k8s-auth-backend-mount-accessor

  app_sa_name      = var.k8s_sa_name_jan_app
  app_sa_namespace = var.k8s_namespace
  app_sa_uid       = module.tf-k8s.k8s-sa-janapp-uid

}

module "cs-sa-sara-vault-app" {
  source = "../../modules/tf-vault-app"
  providers = {
    vault.lob  = vault.sea
    vault.team = vault.sa
  }

  app_name = var.app_name_saraapp
  lob_name = var.lob_sea

  team_name                     = var.team_sa
  team_secret_mount_accessor_id = module.cs-sa-vault-team.vault-team-secret-mount-accessor

  kubernetes_auth_backend_path           = module.cs-vault-lob.vault-lob-k8s-auth-backend-path
  kubernetes_auth_backend_mount_accessor = module.cs-vault-lob.vault-lob-k8s-auth-backend-mount-accessor

  app_sa_name      = var.k8s_sa_name_sara_app
  app_sa_namespace = var.k8s_namespace
  app_sa_uid       = module.tf-k8s.k8s-sa-saraapp-uid

}