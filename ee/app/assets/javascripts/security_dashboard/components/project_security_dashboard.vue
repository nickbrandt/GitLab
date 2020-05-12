<script>
import { isUndefined } from 'lodash';
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ReportsNotConfigured from './empty_states/reports_not_configured.vue';
import SecurityDashboard from './security_dashboard_vuex.vue';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
    Icon,
    ReportsNotConfigured,
    SecurityDashboard,
    TimeagoTooltip,
    UserAvatarLink,
  },
  props: {
    hasPipelineData: {
      type: Boolean,
      required: false,
      default: false,
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
      required: false,
      default: undefined,
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
                s__('SecurityReports|Pipeline %{pipelineLink} triggered %{timeago} by %{user}')
              "
            >
              <template #pipelineLink>
                <gl-link :href="pipeline.path">#{{ pipeline.id }}</gl-link>
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
            <gl-link :href="branch.path" class="monospace">{{ branch.id }}</gl-link>
            <span class="text-muted prepend-left-5 append-right-5">&middot;</span>
            <icon name="commit" />
            <gl-link :href="commit.path" class="monospace">{{ commit.id }}</gl-link>
          </span>
        </div>
      </div>
      <h4>{{ __('Vulnerabilities') }}</h4>
      <security-dashboard
        :lock-to-project="project"
        :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
        :vulnerabilities-count-endpoint="vulnerabilitiesSummaryEndpoint"
        :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
      >
        <template #emptyState>
          <gl-empty-state
            :title="s__(`SecurityReports|No vulnerabilities found for this project`)"
            :svg-path="emptyStateSvgPath"
            :description="
              s__(
                `SecurityReports|While it's rare to have no vulnerabilities for your project, it can happen. In any event, we ask that you double check your settings to make sure you've set up your dashboard correctly.`,
              )
            "
            :primary-button-link="dashboardDocumentation"
            :primary-button-text="s__('SecurityReports|Learn more about setting up your dashboard')"
          />
        </template>
      </security-dashboard>
    </template>
    <reports-not-configured
      v-else
      :svg-path="emptyStateSvgPath"
      :help-path="securityDashboardHelpPath"
    />
  </div>
</template>
