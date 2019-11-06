---
type: reference, how-to
---

# Sourcegraph integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/16556) in GitLab X.X.

[Sourcegraph](https://sourcegraph.com) provides complete code intelligence functionality,
historically provided by the Sourcegraph browser extension. Sourcegraph provides tooltips on hover with go-to definitions as well as
find references working by default for all users.

## Set up for public repositories on GitLab.com

With an opt-in setting, this works by default for all public repositories on GitLab.com.

1. In GitLab, click your avatar in the top-right corner, then **Settings**. On the left-hand nav, click **Preferences**.
1. Under **Integrations**, find the **Sourcegraph** section.
1. Check **Enable Sourcegraph**.

## Set up for private repositories on GitLab.com

Since [Sourcegraph.com](http://sourcegraph.com/search) does not access private repositories on GitLab.com, you will need to run a private instance of Sourcegraph to generate code intelligence.

### Set up and configure your Sourcegraph instance

Follow the [setup](#set-up-your-sourcegraph-instance) and [configure](#configure-your-sourcegraph-instance-with-gitlab) steps in the self-managed instance section below.

### Install the Sourcegraph browser extension

To share code intelligence information from your private Sourcegraph instance, you will need to use the Sourcegraph browser extension to reach back to your private Sourcegraph instance from private GitLab repository pages.

1. [Install the Sourcegraph browser extension](https://docs.sourcegraph.com/integration/browser_extension).
1. Right-click the browser extension icon and set the Sourcegraph URL field to your Sourcegraph instance's URL.
1. [Enable the browser extension](https://docs.sourcegraph.com/integration/browser_extension#enabling-the-browser-extension-on-your-code-host) on GitLab.com.

You should now see code intelligence on any repository indexed by your private Sourcegraph instance.

## Set up for self-managed GitLab instances **(CORE ONLY)**

> Once enabled in your instance, it will become available to all projects (public, internal, and private).

Before you can enable Sourcegraph code intelligence in GitLab you need to have a
Sourcegraph instance running and configured with your GitLab instance as an external
service.

### Set up your Sourcegraph instance

If you are new to Sourcegraph, head over to the [Sourcegraph installation documentation](https://docs.sourcegraph.com/admin) and get your instance up and running.

### Connect your Sourcegraph instance to GitLab

1. Navigate to the site admin area in Sourcegraph.
1. [Configure your GitLab external service](https://docs.sourcegraph.com/admin/external_service/gitlab).
You can skip this step if you already have your GitLab repositories searchable in Sourcegraph.
1. Validate that you can search your repositories from GitLab in your Sourcegraph instance by running a test query.
1. Add your GitLab instance URL to the [`corsOrigin` setting](https://docs.sourcegraph.com/admin/config/site_config#corsOrigin) in your site configuration (e.g. `https://sourcegraph.example.com/site-admin/configuration`).

### Configure your GitLab instance with Sourcegraph

1. In GitLab, go to **Admin Area > Settings > Integrations**.
1. Expand the **Sourcegraph** configuration section.
1. Check **Enable Sourcegraph**.
1. Set the Sourcegraph URL to your Sourcegraph instance, e.g., `https://sourcegraph.example.com`.

You should now see code intelligence on your files, without needing the browser
extension installed!
