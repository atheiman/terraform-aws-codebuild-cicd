# Terraform AWS CodeBuild CI/CD Runner

This Terraform project can quickly setup a CodeBuild project linked to multiple CodeCommit repositories. CodeBuild will run the `buildspec.yml` in each CodeCommit repository when any branch is pushed to. If a branch has an open pull request, the build status will be commented on the pull request.

# Usage

1. Reference this module and deploy using terraform
   ```hcl
   module "codebuild_cicd" {
     source = "atheiman/codebuild-cicd/aws"

     codebuild_service_role_managed_policy_arns = []
   }
   ```

# Roadmap

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
1. Pull request comment Lambda function to check for `buildspec.yml` in branch - if build errors because `buildspec.yml` not found, comment on pull request that the repo should add a `buildspec.yml` to use CI/CD.
