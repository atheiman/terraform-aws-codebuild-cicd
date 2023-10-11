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

1. Make this terraform a consumable module
1. Additional iam policies attached to codebuild service role
1. Quickstart walkthrough
1. Repository name pattern matching to limit which repositories builds are executed for
1. Repositories mapped to CodeBuild IAM service roles
   - Example: repos `a` and `b` use service role `admin` but all other repos use the default service role
   - Implement with complex pattern matching. Dedicated eventbridge rules for each declared repo using `StartBuild` parameter `serviceRoleOverride`. Default rules will need to exclude those repos.
1. Build for codecommit repos in other regions
   - README explanation of cross region event routing https://aws.amazon.com/blogs/compute/introducing-cross-region-event-routing-with-amazon-eventbridge/
1. Support additional tools installed in codebuild image / custom codebuild images?
