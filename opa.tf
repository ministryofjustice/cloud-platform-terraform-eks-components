#######
# OPA #
#######

module "opa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=opa-valid-hostname"
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  enable_invalid_hostname_policy = terraform.workspace == local.live_workspace ? false : true
  dependence_deploy = null_resource.deploy
}

