#variable "metrics_server_version" {
#    type = string
#    description = "Versão do helm chart do metrics server"
#}

variable "prometheus_metrics_server_replicas" {
  type        = string
  description = "Número de replicas do metrics server"
}

variable "prometheus_retention" {
  type        = string
  description = "Tempo de retenção das métricas"
}

variable "prometheus_storageclass_name" {
  type        = string
  description = "Tamanho do disco para o Prometheus"
}

variable "prometheus_disk_size" {
  type        = string
  description = "Tamanho do disco para o Prometheus"
}


variable "grafana_password_admin" {
  type        = string
  description = "Senha usuário admin grafana dashboards"
}

variable "grafana_disk_size" {
  type        = string
  description = "Tamanho do disco para o Grafana"
}

variable "grafana_storageclass_name" {
  type        = string
  description = "Tamanho do disco para o Grafana"
}