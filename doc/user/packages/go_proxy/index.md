# GitLab Go Proxy **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/27376) in [GitLab Premium](https://about.gitlab.com/pricing/) ??.??.

The GitLab Go Proxy implements the Go proxy protocol.

NOTE: **Note:**
GitLab does not (yet) display Go modules in the **Packages** section of a
project. Only the Go proxy protocol is supported at this time, and only for
modules on GitLab.

## Enabling the Go proxy

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled support for the Package Registry](../../../administration/packages/index.md). **(PREMIUM ONLY)**

After the Package Registry is enabled, it will be available for all new projects
by default. To enable it for existing projects, or if you want to disable it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the Packages feature and enable or disable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.
Next, you must configure your development environment to use the Go proxy.

## Adding GitLab as a Go proxy

NOTE: **Note:**
To use a Go proxy, you must be using Go 1.13 or later.

The available proxy endpoints are:

- Project - can fetch modules defined by a project - `/api/v4/projects/:id/packages/go`

Go's use of proxies is configured with the `GOPROXY` environment variable, as a
comma separated list of URLs. Go 1.14 adds support for managing Go's environment
variables via `go env -w`, e.g. `go env -w GOPROXY=...`. This will write to
`$GOPATH/env` (which defaults to `~/.go/env`). `GOPROXY` can also be configured
as a normal environment variable, via RC files or `export GOPROXY=...`.

The default value of `$GOPROXY` is `https://proxy.golang.org,direct`, which
tells `go` to first query `proxy.golang.org` and fallback to direct VCS
operations (`git clone`, `svc checkout`, etc). Replacing
`https://proxy.golang.org` with a GitLab endpoint will direct all fetches
through GitLab. Currently GitLab's Go proxy does not support dependency
proxying, so all external dependencies will be handled directly. If GitLab's
endpoint is inserted before `https://proxy.golang.org`, then all fetches will
first go through GitLab. This can help avoid making requests for private
packages to the public proxy, but `GOPRIVATE` is a much safer way of achieving
that.

## Releasing a module

NOTE: **Note:**
For a complete understanding of Go modules and versioning, see [this series of
blog posts](https://blog.golang.org/using-go-modules) on the official Go
website.

Go modules and module versions are handled entirely via Git (or SVN, Mercurial,
etc). A module is a repository containing Go source and a `go.mod` file. A
version of a module is a Git tag (or equivalent) that is a valid [semantic
version](https://semver.org), prefixed with 'v'. For example, `v1.0.0` and
`v1.3.2-alpha` are valid module versions, but `v1` or `v1.2` are not.

Go requires that major versions after v1 involve a change in the import path of
the module. For example, version 2 of the module `gitlab.com/my/project` must be
imported and released as `gitlab.com/my/project/v2`.

## Valid modules and versions

The GitLab Go proxy will ignore modules and module versions that have an invalid
`module` directive in their `go.mod`. Go requires that a package imported as
`gitlab.com/my/project` can be accessed via that same URL, and that the first
line of `go.mod` is `module gitlab.com/my/project`. If `go.mod` names a
different module, compilation will fail. Additionally, Go requires, for major
versions after 1, that the name of the module have an appropriate suffix, e.g.
`gitlab.com/my/project/v2`. If the `module` directive does not also have this
suffix, compilation will fail.

Go supports 'pseudo-versions' that encode the timestamp and SHA of a commit.
Tags that match the pseudo-version pattern are ignored, as otherwise they could
interfere with fetching specific commits using a pseudo-version. Pseudo-versions
follow one of three formats:

- `vX.0.0-yyyymmddhhmmss-abcdefabcdef`, when no earlier tagged commit exists for X
- `vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`, when most recent prior tag is vX.Y.Z-pre
- `vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef`, when most recent prior tag is vX.Y.Z
