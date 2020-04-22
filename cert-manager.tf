
module "cert_manager" {
  #source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=master"
  source = "/Users/mogaal/workspace/github/ministryofjustice/cloud-platform-terraform-certmanager"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, [data.aws_route53_zone.selected.zone_id])

  # This module requires helm and OPA already deployed
  dependence_prometheus = helm_release.prometheus_operator
  dependence_deploy     = null_resource.deploy
  dependence_opa        = module.opa.helm_opa_status

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}
