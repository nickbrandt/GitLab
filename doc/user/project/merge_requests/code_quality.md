# Code Quality **[STARTER]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1984)
in [GitLab Starter](https://about.gitlab.com/pricing/) 9.3.

## Overview

If you are using [GitLab CI/CD](../../../ci/README.md), you can analyze your
source code quality using GitLab Code Quality.
Code Quality uses [Code Climate Engines](https://codeclimate.com), which are
free and open source. Code Quality doesn’t require a Code Climate subscription.

Going a step further, GitLab can show the Code Quality report right
in the merge request widget area:

![Code Quality Widget](img/code_quality.gif)

## Use cases

For instance, consider the following workflow:

1. Your backend team member starts a new implementation for making certain feature in your app faster
1. With Code Quality reports, they analyze how their implementation is impacting the code quality
1. The metrics show that their code degrade the quality in 10 points
1. You ask a co-worker to help them with this modification
1. They both work on the changes until Code Quality report displays no degradations, only improvements
1. You approve the merge request and authorize its deployment to staging
1. Once verified, their changes are deployed to production

## How it works

First of all, you need to define a job in your `.gitlab-ci.yml` file that generates the
[Code Quality report artifact](../../../ci/yaml/README.md#artifactsreportscodequality).
For more information on how the Code Quality job should look like, check the
example on [analyzing a project's code quality](../../../ci/examples/code_quality.md).

GitLab then checks this report, compares the metrics between the source and target
branches, and shows the information right on the merge request.

>**Note:**
If the Code Quality report doesn't have anything to compare to, no information
will be displayed in the merge request area. That is the case when you add the
Code Quality job in your `.gitlab-ci.yml` for the very first time.
Consecutive merge requests will have something to compare to and the Code Quality
report will be shown properly.
