<script>
import { isUndefined } from 'underscore';
import { s__ } from '~/locale';
import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SecurityDashboardApp from 'ee/security_dashboard/components/app.vue';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    UserAvatarLink,
    Icon,
    TimeagoTooltip,
    SecurityDashboardApp,
  },
  props: {
    hasPipelineData: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyStateIllustrationPath: {
      type: String,
      required: false,
      default: null,
    },
    securityDashboardHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    commit: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    triggeredBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    branch: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    pipeline: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    project: {
      type: Object,
      required: true,
      validator: project => !isUndefined(project.id) && !isUndefined(project.name),
    },
    dashboardDocumentation: {
      type: String,
      required: false,
      default: null,
    },
    emptyStateSvgPath: {
      type: String,
      required: false,
      default: null,
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    vulnerabilitiesEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    vulnerabilitiesSummaryEndpoint: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    emptyStateDescription() {
      return s__(
        `SecurityDashboard|
         The security dashboard displays the latest security report.
         Use it to find and fix vulnerabilities.`,
      ).trim();
    },
  },
};
</script>
<template>
  <div>
    <template v-if="hasPipelineData">
      <div class="card security-dashboard prepend-top-default">
        <div class="card-header border-bottom-0">
          <span class="js-security-dashboard-left">
            <gl-sprintf
              :message="
                s__('SecurityDashboard|Pipeline %{pipelineLink} triggered %{timeago} by %{user}')
              "
            >
              <template #pipelineLink>
                <a :href="pipeline.path">#{{ pipeline.id }}</a>
              </template>
              <template #timeago>
                <timeago-tooltip :time="pipeline.created" />
              </template>
              <template #user>
                <user-avatar-link
                  :link-href="triggeredBy.path"
                  :img-src="triggeredBy.avatarPath"
                  :img-alt="triggeredBy.name"
                  :img-size="24"
                  :username="triggeredBy.name"
                  class="avatar-image-container"
                />
              </template>
            </gl-sprintf>
          </span>
          <span class="js-security-dashboard-right pull-right">
            <icon name="branch" />
            <a :href="branch.path" class="monospace">{{ branch.id }}</a>
            <span class="text-muted prepend-left-5 append-right-5">&middot;</span>
            <icon name="commit" />
            <a :href="commit.path" class="monospace">{{ commit.id }}</a>
          </span>
        </div>
      </div>
      <h4 class="mt-4 mb-3">{{ __('Vulnerabilities') }}</h4>
      <security-dashboard-app
        :lock-to-project="project"
        :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
        :vulnerabilities-count-endpoint="vulnerabilitiesSummaryEndpoint"
        :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      >
        <template #emptyState>
          <gl-empty-state
            :title="s__(`No vulnerabilities found for this project`)"
            :svg-path="emptyStateSvgPath"
            :description="
              s__(
                `While it's rare to have no vulnerabilities for your project, it can happen. In any event, we ask that you double check your settings to make sure you've set up your dashboard correctly.`,
              )
            "
            :primary-button-link="dashboardDocumentation"
            :primary-button-text="
              s__('Security Reports|Learn more about setting up your dashboard')
            "
          />
        </template>
      </security-dashboard-app>
    </template>
    <gl-empty-state
      v-else
      :title="s__('SecurityDashboard|Monitor vulnerabilities in your code')"
      :svg-path="emptyStateIllustrationPath"
      :description="emptyStateDescription"
      :primary-button-link="securityDashboardHelpPath"
      :primary-button-text="__('Learn more')"
    />
  </div>
</template>
