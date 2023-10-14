variable "resources_name" {
  type    = string
  default = "codebuild-cicd"
}

variable "codebuild_concurrent_build_limit" {
  type    = number
  default = 3
}

variable "codebuild_service_role_extra_managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "codebuild_load_buildspec_from_default_branch" {
  type    = bool
  default = true
}

variable "codebuild_extra_environment_variables" {
  type    = list(map(string))
  default = []
}
