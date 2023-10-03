variable "resources_name" {
  type    = string
  default = "codebuild-cicd-runner"
}

variable "create_codecommit_repo" {
  type    = bool
  default = true
}

variable "codecommit_repo_name_prefix_to_watch" {
  type    = string
  default = ""
}

variable "runner_managed_policy_arns" {
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
