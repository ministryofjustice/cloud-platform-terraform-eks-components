
module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=0.2.2"

  alertmanager_slack_receivers = var.alertmanager_slack_receivers
  iam_role_nodes               = data.aws_iam_role.nodes.arn
  pagerduty_config             = var.pagerduty_config

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url

  dependence_deploy = null_resource.deploy
  dependence_opa    = module.opa.helm_opa_status

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}
