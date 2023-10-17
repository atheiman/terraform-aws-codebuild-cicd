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
  description = "On pull request builds, load buildspec.yml from the default branch of the repository being built"
  default     = true
}

variable "codebuild_extra_environment_variables" {
  type        = list(object({ name = string, value = any }))
  description = "Extra environment variables to be set on the CodeBuild project"
  default     = []
}

variable "codecommit_repositories_customizations" {
  type        = map(object({ codebuild_service_role_arn = string }))
  description = "Map of CodeCommit repository names to a map of customizations for the repository. Available customization attributes: codebuild_service_role_arn. codebuild_service_role_arn should trust service principal \"codebuild.amazonaws.com\"."
  default     = {}
}

variable "codecommit_approval_rule_template_associated_repositories" {
  type        = list(string)
  description = "List of existing CodeCommit repositories to which an approval rule template will be applied requiring successful CodeBuild build on pull requests"
  default     = []
}

variable "codecommit_repositories_allowed" {
  type        = list(string)
  description = "List of CodeCommit repositories to be built. If left empty, and `codecommit_repositories_denied` is not specified, all repositories will be built."
  default     = []
}

variable "codecommit_repositories_denied" {
  type        = list(string)
  description = "List of CodeCommit repositories to never be built. If left empty, and `codecommit_repositories_allowed` is not specified, all repositories will be built."
  default     = []
}
