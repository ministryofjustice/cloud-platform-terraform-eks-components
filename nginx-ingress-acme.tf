
#########
# Nginx #
#########

#
# K8S
#

resource "kubernetes_namespace" "ingress_controllers" {
  metadata {
    name = "ingress-controllers"

    labels = {
      "name"                                           = "ingress-controllers"
      "component"                                      = "ingress-controllers"
      "cloud-platform.justice.gov.uk/environment-name" = "production"
      "cloud-platform.justice.gov.uk/is-production"    = "true"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                   = "Kubernetes Ingress Controllers"
      "cloud-platform.justice.gov.uk/business-unit"                 = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"                         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "cloud-platform.justice.gov.uk/can-use-loadbalancer-services" = "true"
    }
  }
}

#
# HELM
#

resource "helm_release" "nginx_ingress_acme" {
  count = var.enable_nginx_ingress_acme ? 1 : 0

  name       = "nginx-ingress-acme"
  repository = "stable"
  chart      = "stable/nginx-ingress"
  namespace  = kubernetes_namespace.ingress_controllers.id
  version    = "v1.24.0"

  values = [templatefile("${path.module}/templates/nginx-ingress-controller.yaml.tpl", {
    cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  })]

  depends_on = [
    null_resource.deploy,
    kubernetes_namespace.ingress_controllers,
    module.opa.helm_opa_status,
  ]
}

#
# Certificate for *.apps.*
# 

data "template_file" "nginx_ingress_default_certificate" {
  template = file(
    "${path.module}/templates/nginx-ingress-controller-default-cert.yaml.tpl",
  )

  vars = {
    common_name = "*.apps.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
    alt_name    = terraform.workspace == local.live_workspace ? format("- '*.%s'", local.live_domain) : ""
  }
}

resource "null_resource" "nginx_ingress_default_certificate" {
  depends_on = [helm_release.cert-manager]

  provisioner "local-exec" {
    command = <<EOS
kubectl apply -n ingress-controllers -f - <<EOF
${data.template_file.nginx_ingress_default_certificate.rendered}
EOF
EOS

  }

  provisioner "local-exec" {
    when = destroy

    command = <<EOS
kubectl delete -n ingress-controllers -f - <<EOF
${data.template_file.nginx_ingress_default_certificate.rendered}
EOF
EOS

  }

  triggers = {
    contents = sha1(
      data.template_file.nginx_ingress_default_certificate.rendered,
    )
  }
}

