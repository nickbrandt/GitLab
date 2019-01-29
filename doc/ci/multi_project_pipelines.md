# Multi-project pipelines **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/2121) in
[GitLab Premium 9.3](https://about.gitlab.com/2017/06/22/gitlab-9-3-released/#multi-project-pipeline-graphs).

When you set up [GitLab CI/CD](README.md) across multiple projects, you can visualize
the entire pipeline, including all cross-project inter-dependencies.

## Overview

GitLab CI/CD is a powerful continuous integration tool that works not only per project, but also across projects. When you
configure GitLab CI for your project, you can visualize the stages
of your [jobs](pipelines.md#jobs) on a [pipeline graph](pipelines.md#pipeline-graphs).

![Multi-project pipeline graph](img/multi_project_pipeline_graph.png)

In the Merge Request Widget, multi-project pipeline mini-graphs are displayed,
and when hovering or tapping (on touchscreen devices) they will expand and be shown adjacent to each other.

![Multi-project mini graph](img/multi_pipeline_mini_graph.gif)

Multi-project pipelines are useful for larger products that require cross-project inter-dependencies, such as those
adopting a [microservices architecture](https://about.gitlab.com/2016/08/16/trends-in-version-control-land-microservices/).

## Use cases

Let's assume you deploy your web app from different projects in GitLab:

- One for the free version, which has its own pipeline that builds and tests your app
- One for the paid version add-ons, which also pass through builds and tests
- One for the documentation, which also builds, tests, and deploys with an SSG

With Multi-Project Pipelines, you can visualize the entire pipeline, including all stages of builds and tests for the three projects.

## How it works

### Creating cross-project pipeline through API

When you use the [`CI_JOB_TOKEN` to trigger pipelines](triggers/README.md#ci-job-token), GitLab
recognizes the source of the job token, and thus internally ties these pipelines
together, allowing you to visualize their relationships on pipeline graphs.

These relationships are displayed in the pipeline graph by showing inbound and
outbound connections for upstream and downstream pipeline dependencies.

### Creating cross-project pipeline in .gitlab-ci.yml

> Introduced in GitLab 11.8

#### Triggering a downstream pipeline using a bridge job

Before GitLab 11.8 it was necessary to implement a pipeline job that was
responsible for making the API request [to trigger a pipeline](triggers/README.md#ci-job-token)
in a different project.

In GitLab 11.8 we introduced a new CI/CD configuration syntax to make this task
easier, and avoid the need of involving GitLab Runner in triggering a
cross-project pipeline.

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my/deployment
```

The example above, as soon as `rspec` job succeeds in stage `test`, `staging`
_bridge_ job is going to be started. Initial status of this job is going to be
`pending`. GitLab will create a downstream pipeline in the `my/deployment`
project, and as soon as the pipeline gets created, `staging` job is going to
succeed. `my/deployment` is a full path to that project.

User that created the upstream pipeline needs to have access rights to the
downstream project (`my/deployment` in this case). If a downstream project can
not be found, or a user does not have access rights to create pipeline there,
`staging` job is going to be marked as _failed_.

Note: `staging` job is going to succeed as soon as a downstream pipeline gets
created. GitLab does not support status attribution yet, however adding
first-class `trigger` configuration syntax is a ground work for implementing
[status attribution](https://gitlab.com/gitlab-org/gitlab-ce/issues/39640).

Note: Bridge jobs do not support every configuration entry that a user can use
in case of regular jobs. Bridge jobs are not going to be picked by a runner,
thus there is no point in adding support for `script`, for example. If a user
tries to used unsupported configuration syntax, YAML validation is going to
fail upon pipeline creation.

#### Specifying a downstream pipeline branch

It is possible to specify a branch name that a downstream pipeline is going to
use.

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

Use a `project` keyword to specify full path to a downstream project. Use
`branch` keyword to specify a branch name.

GitLab is going to use a commit that is currently on the HEAD of the branch
when creating a downstream pipeline.

#### Passing variables to a downstream pipeline

Sometimes you might want to pass variables to a downstream pipeline.
You can do that using `variables` keyword, just like you would do in case
of defining a regular job.

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my/deployment
```

`ENVIRONMENT` variable is going to be passed to every job defined in a
downstream pipeline. It is going to be available as an environment variable
when GitLab Runner picks a job.

#### Limitations

Because bridge jobs are a little different than regular jobs, it is not
possible to use exactly the same configuration syntax here, as one would
normally do when defining a regular job that is going to be picked by a runner.

Some features, are not implemented yet, like support for environments.

Available configuration keywords are:

- `trigger` (to define a downstream pipeline trigger)
- `stage`
- `allow_failure`
- `only` and `except`
- `when`
- `extends`
