# Geo Frequently Asked Questions

## What are the minimum requirements to run Geo?

The requirements are listed [on the index page](index.md#requirements-for-running-geo)

## Can I use Geo in a disaster recovery situation?

Yes, but there are limitations to what we replicate (see
[What data is replicated to a **secondary** node?](#what-data-is-replicated-to-a-secondary-node)).

Read the documentation for [Disaster Recovery](../disaster_recovery/index.md).

## What data is replicated to a **secondary** node?

We currently replicate project repositories, LFS objects, generated
attachments / avatars and the whole database. This means user accounts,
issues, merge requests, groups, project data, etc., will be available for
query.

## Can I git push to a **secondary** node?

Yes!  Pushing directly to a **secondary** node (for both HTTP and SSH, including git-lfs) was [introduced](https://about.gitlab.com/2018/09/22/gitlab-11-3-released/) in [GitLab Premium](https://about.gitlab.com/pricing/#self-managed) 11.3.

## How long does it take to have a commit replicated to a **secondary** node?

All replication operations are asynchronous and are queued to be dispatched. Therefore, it depends on a lot of
factors including the amount of traffic, how big your commit is, the
connectivity between your nodes, your hardware, etc.

## What if the SSH server runs at a different port?

That's totally fine. We use HTTP(s) to fetch repository changes from the **primary** node to all **secondary** nodes.

## Is this possible to set up a Docker Registry for a **secondary** node that mirrors the one on the **primary** node?

Yes. See [Docker Registry for a **secondary** node](docker_registry.md).
