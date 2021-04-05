---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitHub import **(FREE SELF)**

> [Introduced]( https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10308) in GitLab 9.1.

To retrieve and import GitHub repositories, you need a [GitHub personal access token](https://github.com/settings/tokens).
A username should be passed as the second argument to the Rake task,
which becomes the owner of the project. You can resume an import
with the same command.

Bear in mind that the syntax is very specific. Remove any spaces within the argument block and
before/after the brackets. Also, some shells (for example, `zsh`) can interpret the open/close brackets
(`[]`) separately. You may need to either escape the brackets or use double quotes.

## Caveats

If the GitHub [rate limit](https://docs.github.com/en/rest/reference/rate-limit) is reached while
importing, the importing process waits (`sleep()`) until it can continue importing.

## Importing multiple repositories

To import a project from the list of your GitHub projects available:

```shell
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar]" RAILS_ENV=production
```

For these commands:

- `access_token` is your GitHub personal access token.
- `root` is your GitLab username.
- `foo/bar` is the new GitLab namespace/project created from your GitHub project.
  - Subgroups are also possible: `foo/foo/bar`.

## Importing a single repository

To import a specific GitHub project (named `foo/github_repo` here):

```shell
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar,,foo/github_repo]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar,,foo/github_repo]" RAILS_ENV=production
```

For these commands:

- `access_token` is your GitHub personal access token.
- `root` is your GitLab username.
- `foo/bar` is the new GitLab namespace/project created from your GitHub project.
  - Subgroups are also possible: `foo/foo/bar`.
- `foo/github_repo` is the GitHub repository path

## Importing from GitHub Enterprise

To import repositories from GitHub Enterprise, you will need to provide the URL to the GitHub Enterprise instance.

```shell
# Omnibus installations
sudo gitlab-rake "import:github[access_token,root,foo/bar,https://github.company.com,foo/github_repo]"

# Installations from source
bundle exec rake "import:github[access_token,root,foo/bar,https://github.company.com,foo/github_repo]" RAILS_ENV=production
```

For these commands:

- `access_token` is your GitHub personal access token.
- `root` is your GitLab username.
- `foo/bar` is the new GitLab namespace/project created from your GitHub project.
- `https://github.company.com` is the URL to the GitHub Enterprise instance.
