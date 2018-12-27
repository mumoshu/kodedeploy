variable "region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "app_name" {
  description = "CodeDeploy applicatino name"
  default = "lb-app-1"
}

variable "codedeploy_service_role_name" {
  description = "CodeDeploy service role name"
  default = "codedeploy-service"
}

variable "codedeploy_service_role_arn" {
  description = "CodeDeploy service role ARN"
  default = ""
}

variable "env" {
  description = "kodedeploy environment name"
}
