variable "region" {
  type        = string
  description = "region of the provider"
  default     = "us-east-2"
}

variable "owner" {
  type        = string
  description = "the owner of a resource"
  default     = "ztursunbekova"
}

variable "cidr_block" {
  type        = string
  description = "cidr_block of vpc"
}

variable "subnet_prefix-az1" {
  type = list(string)
}

variable "subnet_prefix-az2" {
  type = list(string)
}

variable "availability_zone" {
  type = list(string)
}

variable "web_ec2_type" {
  type = string
}

variable "admin" {
  type = list(string)
  description = "Admin's IP for SSH"
}

