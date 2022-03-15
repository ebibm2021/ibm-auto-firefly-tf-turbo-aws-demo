variable "vpc_name" {
  type    = string
  default = "terraform-vpc"
}

variable "eks_cluster_name" {
  type    = string
  default = "terraform-eks-cluster"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnets_azs" {
  type    = list(string)
  default = ["ap-south-1", "ap-south-1"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "nat_gateways" {
  type    = bool
  default = true
}

variable "security_group_name" {
  type    = string
  default = "ssh"
}

variable "security_group_description" {
  type    = string
  default = "Port 22"
}

variable "ingress_description" {
  type    = string
  default = "Allow SSH access"
}

variable "ingress_protocol" {
  type    = string
  default = "tcp"
}

variable "ingress_from_port" {
  type    = number
  default = 22
}

variable "ingress_to_port" {
  type    = number
  default = 22
}

variable "ingress_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "ingress_ipv6_cidr_blocks" {
  type    = list(string)
  default = null
}
