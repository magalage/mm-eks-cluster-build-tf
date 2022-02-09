variable "region" {
  type = string
}

variable "cluster_subnet_ids" {
  type = list(string)
}

variable "node_subnet_ids" {
  type = list(string)
}
