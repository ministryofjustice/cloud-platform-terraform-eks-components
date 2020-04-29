
module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=0.0.3"

  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.monitoring.helm_prometheus_operator_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}
