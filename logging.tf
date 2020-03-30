module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=0.0.2"

  elasticsearch_host       = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  elasticsearch_audit_host = lookup(var.elasticsearch_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")

  dependence_prometheus       = helm_release.prometheus_operator
  dependence_deploy           = null_resource.deploy
  dependence_priority_classes = kubernetes_priority_class.cluster_critical
}
