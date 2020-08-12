---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Frequently asked questions about the Kubernetes agent

This document collects random bits of knowledge about the project which don't fit anywhere else. Also, see [architecture-related FAQ](architecture.md#faq).

## Why is the build slow? Why does the build pull so many dependencies?

The `agentk` uses [`gitops-engine`](https://github.com/argoproj/gitops-engine) to implement [GitOps](gitops.md). `gitops-engine` for better or worse [depends on `k8s.io/kubernetes`](https://github.com/argoproj/gitops-engine/issues/56) package, which is the whole Kubernetes repository. Even though it uses only a few packages, because of defects in the `go` module resolution code ([one](https://github.com/golang/go/issues/31580), [two](https://github.com/golang/go/issues/33008)), `go.sum` for this project contains all (?) the dependencies of Kubernetes. `go.sum` is used by [Gazelle](https://github.com/bazelbuild/bazel-gazelle) to [generate dependency information](https://github.com/bazelbuild/bazel-gazelle#update-repos) for Bazel. This is why the project has a lot of dependencies to download and hence is slow to build.

## Why does the build print so many `go: finding module` messages?

See the previous entry. Kubernetes uses some packages from Docker, which depend on the `logrus` library. `go` modules support does not like invalid case of imports that some packages use and barfs at it. This is annoying but harmless. It may be fixed in newer Kubernetes/Docker versions already.

## Why `agentk` is written in Go?

Kubernetes is written in Go as is the whole ecosystem round it. One of the reasons for it is to be able to use bits of Kubernetes that it exports as libraries. Some very important libraries don't have analogs in other languages e.g. [informers](https://github.com/kubernetes/client-go/blob/ccd5becdffb7fd8006e31341baaaacd14db2dcb7/tools/cache/shared_informer.go#L34-L183).

## Why is `kas` written in Go and not Ruby?

- Same as the question above, but to a lesser extent - to use libraries from Kubernetes.
- Go is perfect for handling long-running connections, Ruby on Rails is not as good.

## Why is `kas` not part of the Ruby monolith?

Because it's not written in Ruby.
