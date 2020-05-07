module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.0.3"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}"])

  # EKS doesn't use KIAM but it is a requirement for the module.
  dependence_kiam   = ""
  dependence_deploy = null_resource.deploy

  # This section is for EKS
  eks                         = true
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}
