# provider "kubernetes" {}
#
# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }
#
#   data {
#     mapRoles = <<ROLES
#   |
#     - rolearn: ${var.role_arn}
#       username: system:node:{{EC2PrivateDNSName}}
#       groups:
#        - system:bootstrappers
#        - system:nodes
# ROLES
#   }
# }
#
# provider "helm" {
#   install_tiller  = true
#   namespace       = "kube-system"
#   service_account = "tiller"
#   home            = "./.helm"
# }
#
# git clone https://github.com/instana/instana-helm-chart.git
# cd instana-helm-chart
#
# helm install . --name instana-agent --namespace instana-agent \
# --set instana.agent.key=ArphVGL6T2iGB7Ic1qL2TQ \
# --set instana.agent.endpoint.host=saas-eu-west-1.instana.io \
# --set instana.agent.endpoint.port=443 \
# --set instana.zone=K8s-cluster
#

