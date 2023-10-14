variable "resources_name" {
  type        = string
  description = "Name (or name prefix) to be set on resources created by this module"
  default     = "codebuild-cicd"
}

variable "codebuild_concurrent_build_limit" {
  type        = number
  description = "Limit on CodeBuild project concurrent builds"
  default     = 3
}

variable "codebuild_service_role_extra_managed_policy_arns" {
  type        = list(string)
  description = "Extra IAM policy ARNs to attach to the CodeBuild service role"
  default     = []
}

variable "codebuild_load_buildspec_from_default_branch" {
  type        = bool
  description = "Load buildspec.yml from the default branch of a repository on pull request builds"
  default     = true
}

variable "codebuild_extra_environment_variables" {
  type        = list(object({ name = string, value = any }))
  description = "Extra environment variables to be set on the CodeBuild project"
  default     = []
}
