---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Background Migrations **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326760) in GitLab 13.12.
> - [Deployed behind a feature flag](../../../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-background-migrations). **(FREE SELF)**

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../../../user/feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

This page shows the status of background migrations for the current GitLab instance. All migrations
need to be finished before upgrading GitLab.

![Background migrations](img/background_migrations_v13_12.png)

### Enable or disable Background Migrations **(FREE SELF)**

Background Migrations is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:execute_batched_migrations_on_schedule)
```

To disable it:

```ruby
Feature.disable(:execute_batched_migrations_on_schedule)
```
