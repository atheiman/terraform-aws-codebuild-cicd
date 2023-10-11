variable "resources_name" {
  type    = string
  default = "codebuild-cicd"
}

variable "codecommit_repo_name_prefix_to_watch" {
  description = "TODO - not yet implemented"
  type        = string
  default     = ""
}

variable "codecommit_default_branches" {
  type    = list(string)
  default = ["main", "master"]
}

variable "codebuild_concurrent_build_limit" {
  type    = number
  default = 3
}

variable "codebuild_service_role_extra_managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "artifacts_bucket_name" {
  type        = string
  description = "If left as default (empty string), bucket name will be: $${var.resources_name}-$${accountid}-$${region}"
  default     = ""
}

variable "artifacts_bucket_force_destroy" {
  type = bool
  # TODO
  #default = false
  default = true
}

variable "codebuild_extra_environment_variables" {
  type    = list(map(string))
  default = []
}
