variable "prod_account_id" {
  description = "AWS account ID of App W's prod account (may assume the appw/prod reader role)."
  type        = string
  default     = "222222222222"
}

variable "staging_account_id" {
  description = "AWS account ID of App W's staging account (may assume the appw/staging reader role)."
  type        = string
  default     = "333333333333"
}

variable "app_workload_role_name" {
  description = "Name of App W's prod workload role (Lambda/EC2/ECS task) that needs to read secrets. Lives in the prod app account."
  type        = string
  default     = "appw-workload"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
