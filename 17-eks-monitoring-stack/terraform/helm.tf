resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
  version    = "56.6.2"

  values = [
    yamlencode({
      grafana = {
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = true
          size    = "5Gi"
        }
      }
      prometheus = {
        prometheusSpec = {
          retention = "15d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
        }
      }
      alertmanager = {
        enabled = true
      }
    })
  ]

  depends_on = [module.eks]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.0"

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls}" # Often needed in EKS depending on config
  }

  depends_on = [module.eks]
}
