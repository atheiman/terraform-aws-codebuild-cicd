# Terraform AWS CodeBuild CI/CD Runner

This Terraform project can quickly setup a CodeBuild project linked to multiple CodeCommit repositories. CodeBuild will run the `buildspec.yml` in each CodeCommit repository when any branch is pushed to. If a branch has an open pull request, the build status will be commented on the pull request.

# Usage

1. Reference this module and deploy using terraform locally
   ```hcl
   # TODO
   module "tf_cicd" {
     source = "whatever"
   }
   ```
1. Update the terraform to use provider role shown in the outputs
1. Commit the terraform to a new branch of the codecommit repository
1. Create a pull request and review the terraform plan on the pull request
1. Merge the pull request and see the plan applied
1. Create additional terraform codecommit repositories following the naming scheme and they will also have integrated terraform plan and applies

# TODO

Make this terraform a consumable module
