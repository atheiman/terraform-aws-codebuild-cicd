# terraform-aws-codebuild-cicd

Terraform module to quickly setup a CodeBuild project linked to multiple CodeCommit repositories. CodeBuild will run the `buildspec.yml` in each CodeCommit repository when `main` or `master` branch is pushed to. If a branch has an open pull request, a build will run for the pull request source branch and the build status will be commented on the pull request.

- GitHub: https://github.com/atheiman/terraform-aws-codebuild-cicd
- Terraform Registry: https://registry.terraform.io/modules/atheiman/codebuild-cicd/aws

## Module Example Usage

```hcl
module "codebuild_cicd" {
  source = "atheiman/codebuild-cicd/aws"

  ######################
  # Optional Variables #
  ######################

  # Specify extra IAM policy ARNs to attach to the CodeBuild service role
  # Warning - these permissions will be available to all builds on all CodeCommit repositories
  codebuild_service_role_extra_managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]

  # Recommended to namespace extra environment variables with `CI_` or other prefix to avoid
  # built-in environment variable collisions
  codebuild_extra_environment_variables = [
    {
      name  = "CI_MY_COLOR"
      value = "blue"
    },
    {
      name  = "CI_MY_NUMBER"
      value = 4 # Will be converted to string
    },
  ]
}
```

## Full Walkthrough

### Deploy the Terraform project

1. In a new directory, reference this Terraform module and specify an external [Terraform Backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration). If you need an [S3 backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3), you can create one in your account using [this CloudFormation template](https://gist.githubusercontent.com/atheiman/055cfc07fe3cbdc7ec54fa40b180900d/raw/9716e27ddd67a1b5094a59424b68f171eba729f3/TerraformS3Backend.yml).
   ```hcl
   # main.tf

   module "codebuild_cicd" {
     source = "atheiman/codebuild-cicd/aws"
   }
   ```

   ```hcl
   # backend.tf

   terraform {
     backend "s3" {
       region         = "us-east-1"
       bucket         = "my-tf-state-bucket"
       key            = "codebuild-cicd.tfstate"
       dynamodb_table = "my-tf-state-lock-table"
     }
   }
   ```
1. Initialize and deploy the new terraform project. You will need to [configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html). You should be able to run `aws sts get-caller-identity` and get a response showing your expected IAM user or role.
   ```shell
   # initialize terraform
   terraform init -reconfigure

   # review resources to be created
   terraform plan -out tfplan.binary

   # apply the saved plan
   terraform apply tfplan.binary
   ```

### Automatically build the `main` branch of a CodeCommit repository

1. Create a CodeCommit repository to use the CI/CD functionality
   1. Open the CodeCommit console in the same account and region you deployed the terraform above
   1. Create a repository named `example-cicd-usage`
   1. Add a `buildspec.yml` file to the `main` branch:
      ```yaml
      # https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-syntax
      version: 0.2
      phases:
        build:
          commands:
          - env | sort
          - echo "Running build for source '$CODEBUILD_SOURCE_VERSION'"
          - if [ "$CODEBUILD_SOURCE_VERSION" == 'main' ]; then
              echo "Do something special on builds for the 'main' branch here";
            fi
      ```
1. View the CodeBuild build for the `main` branch of your repository
   1. Open the CodeBuild console in the same account and region you deployed the terraform above.
   1. Open the build project named `codebuild-cicd`.
   1. You should see a build in the build history with status `In progress` or `Succeeded`. By default, builds are automatically started for any CodeCommit repository when the `main` or `master` branch is updated.
   1. In the build logs, you can see the build ran the commands specified in `buildspec.yml`. The output should include `Do something special on builds for the 'main' branch here` because this build was run on the `main` branch.

### Automatically build and post build status to pull requests

1. Create a feature branch `my-feature` from the branch `main` on the `example-cicd-usage` CodeCommit repository created above.
1. Update `buildspec.yml` on the `my-feature` branch to add a new command in the build that will check the syntax of Python files:
   ```yaml
   # https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec-ref-syntax
   version: 0.2
   phases:
     build:
       commands:
       - env | sort
       - echo "Running build for source '$CODEBUILD_SOURCE_VERSION'"

       - python -m py_compile *.py

       - if [ "$CODEBUILD_SOURCE_VERSION" == 'main' ]; then
           echo "Do something special on builds for the 'main' branch here";
         fi
   ```
1. Add a Python file `script.py` on the `my-feature` branch with the below content to be checked by the build:
   ```python
   print "hello world"
   ```
1. Create a pull request in the CodeCommit repository `example-cicd-usage`. Set the source branch to `my-feature` and the destination branch to `main`. You can title the pull request `Example pull request with CI/CD`.
1. Wait a minute after creating the pull request, then open the `Activity` tab on the pull request you created. You should see a new comment from `codebuild-cicd-pull-request-build-status` with a message similar to "⏱ CodeBuild build IN_PROGRESS for commit b829bd89: 3afb3af0-408d-49d4-8a53-d95ac033aea9". Click the link to the build to open the running build for the pull request.
1. After another minute the build should complete. On the pull request `Activity` tab, you will see a new comment similar to: "❌ CodeBuild build FAILED for commit b829bd89: 3afb3af0-408d-49d4-8a53-d95ac033aea9". Click the link to open the failed build for the pull request. You can see at the end of the build logs, the build failed because the file `script.py` has a syntax error:
   ```
   [Container] 2023/10/11 14:50:23 Running command python -m py_compile *.py
     File "script.py", line 1
       print "hello world"
       ^^^^^^^^^^^^^^^^^^^
   SyntaxError: Missing parentheses in call to 'print'. Did you mean print(...)?
   ```
1. Update `script.py` on the `my-feature` branch with the below content:
   ```python
   print("hello world")
   ```
1. Return to the pull request that is now updated with your new commit. Within a couple minutes, you should see two new comments from `codebuild-cicd-pull-request-build-status` on the `Activity` tab of the pull request similar to the below (note that comments are sorted newest on top):
   1. ✅ CodeBuild build SUCCEEDED for commit f22cceb8: bded770d-3514-478b-83a9-89289fd57c14
   1. ⏱ CodeBuild build IN_PROGRESS for commit f22cceb8: bded770d-3514-478b-83a9-89289fd57c14
1. You can now merge this pull request with confidence that the build commands specified in `buildspec.yml` have passed for the feature branch `my-feature`.
1. When you merge the feature branch into `main`, the build will be started again for the updated `main` branch.

### Manage the CodeBuild CI/CD infrastructure within CodeCommit and deploy with CodeBuild

1. Grant additional permissions to the CodeBuild service role using the module variable `codebuild_service_role_managed_policy_arns`. Apply the updated terraform locally.
1. Put the Terraform from above into a new CodeCommit repository. You will need at least the `module {}` reference, and the `backend {}` configuration. Optionally add a [`.gitignore` for Terraform](https://www.toptal.com/developers/gitignore/api/terraform) and `README.md`.
1. Update the `buildspec.yml` commands:
   - all branches: `terraform fmt -recursive && terraform init -reconfigure && terraform plan`
   - `main` branch: `terraform apply`

### Limitations

Currently the `buildspec.yml` can be updated on a feature branch to do anything. Items exist on the roadmap below to handle this problem. For now, just be aware that any permissions granted to the CodeBuild service role will be available to all projects to use in their builds on the `main` or `master` branch, and in pull requests. You can review the default permissions granted to the CodeBuild service role - [see `aws_iam_role_policy.codebuild` in `codebuild.tf` on GitHub](https://github.com/atheiman/terraform-aws-codebuild-cicd/blob/main/codebuild.tf).

## Roadmap

1. Read `buildspec.yml` only from default branch - not sure if this is possible
1. Only build pull requests once approved by a different user
1. Use artifact bucket for storage
1. Restrict elevated permissions to `main` / `master` builds?
1. Repository name pattern matching to limit which repositories builds are executed for
   - List and/or pattern of repo names to build / not build? Probably easier to just do a list of what to build and what not to build?
1. Repositories mapped to CodeBuild IAM service roles
   - Example: repos `a` and `b` use service role `admin` but all other repos use the default service role
   - Implement with complex pattern matching. Dedicated eventbridge rules for each declared repo using `StartBuild` parameter `serviceRoleOverride`. Default rules will need to exclude those repos.
1. Build for codecommit repos in other regions
   - README explanation of cross region event routing https://aws.amazon.com/blogs/compute/introducing-cross-region-event-routing-with-amazon-eventbridge/
1. Support additional tools installed in codebuild image / custom codebuild images?
1. Pull request comment Lambda function to check for `buildspec.yml` in branch - if build errors because `buildspec.yml` not found, comment on pull request that the repo should add a `buildspec.yml` to use CI/CD.
1. Pull request Lambda function to approve pull requests when builds succeed, and remove approval when builds are in progress.
1. Create and apply a pull request approval template that requires pull request Lambda function to approve a pull request? Would only want to apply to a specified list of repositories.
