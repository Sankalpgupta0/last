variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-north-1"
}

variable "name" {
  description = "Name prefix for every resource."
  type        = string
  default     = "privatebin"
}

variable "owner" {
  description = "Value of the Owner tag."
  type        = string
}

variable "environment" {
  description = "Value of the Environment tag."
  type        = string
  default     = "lab"
}

variable "allowed_cidr" {
  description = "The only CIDR allowed to reach port 3344 (your own IP, e.g. 203.0.113.7/32)."
  type        = string
}

variable "app_port" {
  description = "Host port the app is published on."
  type        = number
  default     = 3344
}

variable "privatebin_version" {
  description = "Tag of the privatebin/s3 image."
  type        = string
  default     = "2.1.1"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "noncurrent_version_days" {
  description = "Days before old (noncurrent) object versions are expired."
  type        = number
  default     = 30
}
