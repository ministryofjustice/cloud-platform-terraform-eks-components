

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "cloud-platform-eks/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "aws_iam_role" "nodes" {
  name = data.terraform_remote_state.cluster.outputs.eks_worker_iam_role_name
}

data "aws_route53_zone" "selected" {
  name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}

data "helm_repository" "cloud_platform" {
  name = "cloud-platform"
  url  = "https://ministryofjustice.github.io/cloud-platform-helm-charts"
}

locals {
  live_workspace = "live-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}

# 
# Helm
# 

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
    api_group = ""
  }
}

resource "null_resource" "deploy" {
  depends_on = [
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller,
    null_resource.calico_deploy,
  ]

  provisioner "local-exec" {
    command = "helm init --wait --service-account tiller"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl -n kube-system delete deployment.apps/tiller-deploy service/tiller-deploy"
  }
}


#
# Calico
#

resource "null_resource" "calico_deploy" {

  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5/config/v1.5/calico.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5/config/v1.5/calico.yaml"
  }
}
