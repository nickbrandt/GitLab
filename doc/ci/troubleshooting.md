---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# Troubleshooting CI/CD

Troubleshooting your pipelines is an important part of the process, and GitLab provides several tools to help make testing your pipelines easier. See also below for common issues and their solutions.

## Editing

The [GitLab Web IDE](../user/project/web_ide/index.md) offers advanced authoring tools, including syntax highlighting for the `.gitlab-ci.yml`, and is the recommended editing experience (rather than the single file editor). If you prefer to use another editor, you can use a schema like [this externally maintained one](https://json.schemastore.org/gitlab-ci) with your editor of choice.

## CI Reference Documentation

The [`gitlab-ci.yml` complete reference](yaml/README.md) contains everything you may need to know on how pipelines are defined. There are also some more complex authoring features that have their own detailed usage guides that we recommend looking at if you are considering using these features:

- The [`rules` keyword](yaml/README.md#rules) behaves quite different if you are coming from `only/except`, so be sure to check out the guide if that's your situation. The section on [common `if` clauses](yaml/README.md#common-if-clauses-for-rules) can be very helpful for examples.
- [Multi-project pipelines](multi_project_pipelines.md).
- [Child/parent pipelines](parent_child_pipelines.md) (running a separate `.gitlab-ci.yml` in the same repository as a connected but separate pipeline) and [Dynamic child/parent pipelines](parent_child_pipelines.md#dynamic-child-pipelines) which allows you to dynamically generate the child pipeline's YAML at runtime).
- [Pipelines for Merge Requests](merge_request_pipelines/index.md) (running a pipeline in the context of a merge request), [Pipelines for Merge Results](merge_request_pipelines/pipelines_for_merged_results/index.md) (the same, but on the combined ref of the source and target branch), and [Merge Trains](merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md) (the previous two combined, and automatically queued and merged in sequence).

Apart from these, looking at [examples](examples/README.md) in the documentation can be helpful and we have several.

## Linter

The [CI Linter](yaml/README.md#validate-the-gitlab-ciyml) can be helpful for making sure your syntax is correct.

## Guides

There are various troubleshooting guides available for different topic areas/features:

- [Container Registry](../user/packages/container_registry/index.md#troubleshooting-the-gitlab-container-registry)
- [GitLab Runner](https://docs.gitlab.com/runner/faq/)
- [Merge Trains](merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md#troubleshooting)
- [Docker Build](docker/using_docker_build.md#troubleshooting)
- [Environments](environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time)

## Common issues and their resolution

### `fatal: reference is not a tree`

See the details about how to fix this error on the [pipelines reference page](pipelines/index.md#troubleshooting-fatal-reference-is-not-a-tree).

### Duplicate pipelines with Pipelines for MRs

This is typically caused by the different behavior of `rules`. Take a look at the [`workflow:rules` templates](yaml/README.md#workflowrules-templates) for ready to add solutions for this issue.

### My pipeline didn't create the job I expected

GitLab determines if a job is run based on the [`only/except`](yaml/README.md#onlyexcept-basic) or [`rules`](yaml/README.md#rules) defined on your job. If it didn't run, perhaps it is not evaluating as you expect. Confusion around what [different predefined variables mean/values they provide](variables/predefined_variables.md) (for example `CI_PIPELINE_SOURCE`), can be a source of problems here, so it's worth double checking the definitions if you rely on any and they are not behaving as you expect.

### My pipeline didn't run at all

This can happen when the [`rules`](yaml/README.md#rules) or `only/except` definitions for your pipeline didn't result in _any_ jobs being created for this instance. Check the troubleshooting steps above for jobs, and also double check your [`workflow: rules`](yaml/README.md#workflowrules) section if you are using one; that defines the rules for the entire pipeline.

### My pipeline runs despite the rules I set up

A common case where this happens is when a tag is pushed or a new branch is created, in which case `only/except` and `rules` for `changes` matches every file in the repository (for example, every file is "new" to that branch). If you think of a new tag or branch as having _no_ changes, this can be surprising. Using a rule like the following (mentioned in the [docs for `rules`](yaml/README.md#common-if-clauses-for-rules)) can be helpful here:

```yaml
rules:
  - if: $CI_COMMIT_BEFORE_SHA == '0000000000000000000000000000000000000000'
    when: never
```

### Merge request pipeline widget

The merge request pipeline widget shows information about the pipeline status in a Merge Request. It's displayed above the [merge request ability to merge widget](#merge-request-ability-to-merge-widget). There are a few messages there that you might run into:

There are several messages that can be displayed depending on the status of the pipeline.

#### "Checking pipeline status"

This message is shown when the merge request has no pipeline associated with the latest commit yet. This might be because:

- GitLab hasn't finished creating the pipeline yet.
- You are using an external CI service and GitLab hasn't heard back from the service yet.
- You are not using CI/CD pipelines in your project.
- The latest pipeline was deleted (this is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)).

After the pipeline is created, the message will update with the pipeline status.

#### Merge request ability to merge widget

The merge request status widget shows the **Merge** button and whether or not a merge request is ready to merge. If the merge request can't be merged, the reason for this is displayed.

If the pipeline is still running, the **Merge** button is replaced with the **Merge when pipeline succeeds** button.

If [**Merge Trains**](merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md) are enabled, the button is either **Add to merge train** or **Add to merge train when pipeline succeeds**. **(PREMIUM)**

#### "A CI/CD pipeline must run and be successful before merge"

This message is shown if the [Pipelines must succeed](../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds) setting is enabled in the project and a pipeline has not yet run successfully. This also applies if the pipeline has not been created yet, or if you are waiting for an external CI service. If you don't use pipelines for your project, then you should disable **Pipelines must succeed** so you can accept merge requests.

## Pipeline warnings

Pipeline configuration warnings are shown when you:

- [Validate configuration with the CI Lint tool](yaml/README.md#validate-the-gitlab-ciyml).
- [Manually run a pipeline](pipelines/index.md#run-a-pipeline-manually).

### "Job may allow multiple pipelines to run for a single action"

When you use [`rules`](yaml/README.md#rules) with a `when:` clause without
an `if:` clause, multiple pipelines may run. Usually
this occurs when you push a commit to a branch that has an open merge request associated with it.

To [prevent duplicate pipelines](yaml/README.md#prevent-duplicate-pipelines), use
[`workflow: rules`](yaml/README.md#workflowrules) or rewrite your rules
to control which pipelines can run.

## How to get help

- [GitLab Community Forum](https://forum.gitlab.com/)
- [Support](https://about.gitlab.com/support/)
