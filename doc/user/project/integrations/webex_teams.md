# Webex Teams service

The Webex Teams service sends notifications from GitLab to the conversation for which the webhook was created.

## On Webex Teams

1. Open <https://apphub.webex.com/teams/applications/incoming-webhooks-cisco-systems> in your browser
1. Click on **Connect** Button and authenticate yourself if required
1. Scroll down and define the name of the webhook in the space and select the space for the webhook.
1. Click **ADD** and copy the **Webhook URL** of your webhook.

For more information, see the [Webex Teams documentation for configuring incoming webhooks](https://apphub.webex.com/teams/applications/incoming-webhooks-cisco-systems).

## On GitLab

When you have the **Webhook URL** for your Webex Teams conversation webhook, you can set up the GitLab service.

1. Navigate to the [Integrations page](overview.md#accessing-integrations) in your project's settings, i.e. **Project > Settings > Integrations**.
1. Select the **Webex Teams** integration to configure it.
1. Ensure that the **Active** checkbox is enabled.
1. Check the checkboxes corresponding to the GitLab events you want to receive in Webex Teams.
1. Paste the **Webhook URL** that you copied from the Webex Teams Incoming Webhook configuration step.
1. Configure the remaining options and click `Test settings and save changes`.

Your Webex Teams space will now start receiving GitLab event notifications as configured.

![Webex Teams configuration](img/webex_teams_configuration.png)
