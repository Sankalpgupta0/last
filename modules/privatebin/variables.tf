variable "region" {
  description = "AWS region (used for the bucket name and the app config)."
  type        = string
}

variable "name" {
  description = "Name prefix for every resource."
  type        = string
  default     = "privatebin"
}

variable "tags" {
  description = "Tags for resources that the provider default_tags cannot reach (the root volume)."
  type        = map(string)
  default     = {}
}

variable "allowed_cidr" {
  description = "The only CIDR allowed to reach port 3344 (your own IP, e.g. 203.0.113.7/32)."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_cidr, 0)) && var.allowed_cidr != "0.0.0.0/0"
    error_message = "allowed_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "app_port" {
  description = "Host port the app is published on."
  type        = number
  default     = 3344
}

variable "privatebin_version" {
  description = "Tag of the privatebin/s3 image."
  type        = string
  default     = "2.0.6"
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
