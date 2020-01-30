###############
# ExternalDNS #
###############

#
# HELM
#

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name      = "external-dns"
  chart     = "stable/external-dns"
  namespace = "kube-system"
  version   = "2.6.4"

  values = [templatefile("${path.module}/templates/external-dns.yaml.tpl", {
    domainFilters = lookup(var.cluster_r53_domainfilters, terraform.workspace, [ data.terraform_remote_state.cluster.outputs.cluster_domain_name ])
    iam_role      = aws_iam_role.externaldns.name
    cluster       = terraform.workspace
  })]

  depends_on = [
    null_resource.deploy,
  ]
}

#
# IAM
#

resource "aws_iam_role" "externaldns" {
  name               = "externaldns.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.allow_to_assume.json
}

resource "aws_iam_role_policy_attachment" "externaldns_attach_policy" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns.arn
}

resource "aws_iam_policy" "externaldns" {
  name        = "externaldns.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  path        = "/"
  description = "Policy that allows change DNS entries for the externalDNS service"
  policy      = data.aws_iam_policy_document.externaldns.json
}

data "aws_iam_policy_document" "externaldns" {

  # Sometimes, depending of the situation (e.g manager cluster) it needs to manage
  # another hostzones
  statement {
    actions = ["route53:ChangeResourceRecordSets"]

    resources = lookup(var.cluster_r53_resource_maps, terraform.workspace, [ "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}" ] ) 
  }

  # Always it will manage its own hostzone.
  statement {
    actions = ["route53:ChangeResourceRecordSets"]

    resources = ["${format("arn:aws:route53:::hostedzone/%s", data.aws_route53_zone.selected.zone_id)}"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    resources = ["*"]
  }
}
