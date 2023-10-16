# Receives EventBridge events like the below examples, and starts a build in CodeBuild

# Example 'CodeCommit Repository State Change' event
# {
#     "version": "0",
#     "id": "3f7101d2-f1c4-d0a4-6d89-69fc887cc5e4",
#     "detail-type": "CodeCommit Repository State Change",
#     "source": "aws.codecommit",
#     "account": "111111111111",
#     "time": "2023-10-10T21:05:45Z",
#     "region": "us-east-1",
#     "resources": ["arn:aws:codecommit:us-east-1:111111111111:some-repo"],
#     "detail": {
#         "callerUserArn": "arn:aws:iam::111111111111:user/admin",
#         "commitId": "f485fcc95a795517f279d0a877227e51208b0dfc",
#         "event": "referenceUpdated",
#         "oldCommitId": "a399698fbd740af9c78fb2dd7f667656b70646b6",
#         "referenceFullName": "refs/heads/main",
#         "referenceName": "main",
#         "referenceType": "branch",
#         "repositoryId": "280e6f04-7a9c-4c72-8d8f-947d83e21a96",
#         "repositoryName": "some-repo"
#     }
# }

# Example 'CodeCommit Pull Request State Change' event
# {
#     "version": "0",
#     "id": "6d29aaa0-f4a6-7745-6ec1-cf1587935aef",
#     "detail-type": "CodeCommit Pull Request State Change",
#     "source": "aws.codecommit",
#     "account": "111111111111",
#     "time": "2023-10-10T21:33:04Z",
#     "region": "us-east-1",
#     "resources": ["arn:aws:codecommit:us-east-1:111111111111:some-repo"],
#     "detail": {
#         "author": "arn:aws:sts::111111111111:assumed-role/some-role/some-session",
#         "callerUserArn": "arn:aws:sts::111111111111:assumed-role/some-role/some-session",
#         "creationDate": "Tue Oct 10 21:32:51 UTC 2023",
#         "destinationCommit": "6a3cf62d6b847143c58d8fcbb50dfd61f1ca2450",
#         "destinationReference": "refs/heads/main",
#         "event": "pullRequestCreated",
#         "isMerged": "False",
#         "lastModifiedDate": "Tue Oct 10 21:32:51 UTC 2023",
#         "notificationBody": "A pull request event occurred ...",
#         "pullRequestId": "1",
#         "pullRequestStatus": "Open",
#         "repositoryNames": ["some-repo"],
#         "revisionId": "a4b86e55d3c8110b527e7b1cbcbc3269dbe8aa53e6b0c436791346cd45ac82a0",
#         "sourceCommit": "5c020b042dd71daa6e6cade586cf862a2e7e4f96",
#         "sourceReference": "refs/heads/feature-branch",
#         "title": "some feature"
#     }
# }


import base64
import datetime
import boto3
import os
import json

codecommit = boto3.client("codecommit", region_name=os.environ["AWS_REGION"])
codebuild = boto3.client("codebuild", region_name=os.environ["AWS_REGION"])


def handler(event, context):
    print("received event:")
    print(json.dumps(event))

    if event["detail-type"] not in [
        "CodeCommit Repository State Change",
        "CodeCommit Pull Request State Change",
    ]:
        raise Exception(f"Error - Unexpected event received, detail-type: '{event['detail-type']}'")

    region = event["region"]
    repo_arn = event["resources"][0]
    repo_name = repo_arn.split(":")[-1]
    buildspec = "buildspec.yml"
    repo = codecommit.get_repository(repositoryName="example-cicd-usage")["repositoryMetadata"]
    default_branch = repo["defaultBranch"]

    repo_customizations = json.loads(os.environ["REPOSITORY_CUSTOMIZATIONS_JSON"]).get(repo_name, {})

    build_env_vars = [
        {"name": "CI_REPOSITORY_NAME", "value": repo_name, "type": "PLAINTEXT"},
    ]

    start_build_kwargs = {
        "projectName": os.environ["CODEBUILD_PROJECT_NAME"],
        "buildspecOverride": buildspec,
        "environmentVariablesOverride": build_env_vars,
        "sourceLocationOverride": f"https://git-codecommit.{region}.amazonaws.com/v1/repos/{repo_name}",
        "sourceTypeOverride": "CODECOMMIT",
    }

    if "codebuild_service_role_arn" in repo_customizations:
        start_build_kwargs["serviceRoleOverride"] = repo_customizations["codebuild_service_role_arn"].split("/")[-1]

    # Branch events
    if event["detail-type"] == "CodeCommit Repository State Change":
        if event["detail"]["referenceType"] != "branch" or event["detail"]["referenceName"] != default_branch:
            # Only build default branch
            return

        build_env_vars += [
            {"name": "CI_COMMIT_REF_NAME", "value": event["detail"]["referenceName"], "type": "PLAINTEXT"},
        ]

        start_build_kwargs = start_build_kwargs | {
            "environmentVariablesOverride": build_env_vars,
            "sourceVersion": event["detail"]["referenceName"],
        }

    # Pull request events
    if event["detail-type"] == "CodeCommit Pull Request State Change":
        if os.environ["CODEBUILD_LOAD_BUILDSPEC_FROM_DEFAULT_BRANCH"].lower() == "true":
            buildspec_file_b = codecommit.get_file(
                repositoryName=repo_name, commitSpecifier=default_branch, filePath="buildspec.yml"
            )
            buildspec = buildspec_file_b["fileContent"].decode()

        build_env_vars += [
            {
                "name": "CI_COMMIT_REF_NAME",
                "value": event["detail"]["sourceReference"].split("/")[-1],
                "type": "PLAINTEXT",
            },
            {"name": "CI_DESTINATION_COMMIT", "value": event["detail"]["destinationCommit"], "type": "PLAINTEXT"},
            {"name": "CI_PULL_REQUEST_ID", "value": event["detail"]["pullRequestId"], "type": "PLAINTEXT"},
            {"name": "CI_SOURCE_COMMIT", "value": event["detail"]["sourceCommit"], "type": "PLAINTEXT"},
        ]

        start_build_kwargs = start_build_kwargs | {
            "buildspecOverride": buildspec,
            "environmentVariablesOverride": build_env_vars,
            "sourceVersion": event["detail"]["sourceCommit"],
        }

    print("starting CodeBuild with arguments:")
    print(json.dumps(start_build_kwargs))

    build = codebuild.start_build(**start_build_kwargs)["build"]
    print("CodeBuild started:", build["arn"])
