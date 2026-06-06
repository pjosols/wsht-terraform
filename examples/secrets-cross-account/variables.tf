variable "app_account_id" {
  description = "AWS account ID of the App W (consumer) account that may assume the reader role."
  type        = string
  default     = "222222222222"
}

variable "app_workload_role_name" {
  description = "Name of App W's workload role (Lambda/EC2/ECS task) that needs to read secrets. Lives in the app account."
  type        = string
  default     = "appw-workload"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
