
#########
# Nginx #
#########

module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=0.0.3"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = false

  # This module requires helm and OPA already deployed
  dependence_prometheus  = helm_release.prometheus_operator
  dependence_deploy      = null_resource.deploy
  dependence_opa         = module.opa.helm_opa_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}

