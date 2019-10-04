<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import DeploymentInfo from './deployment_info.vue';
import DeploymentViewButton from './deployment_view_button.vue';
import DeploymentManualButton from './deployment_manual_button.vue';
import DeploymentRedeployButton from './deployment_redeploy_button.vue';
import DeploymentStopButton from './deployment_stop_button.vue';

export default {
  // name: 'Deployment' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'Deployment',
  components: {
    DeploymentInfo,
    DeploymentManualButton,
    DeploymentRedeployButton,
    DeploymentStopButton,
    DeploymentViewButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    showMetrics: {
      type: Boolean,
      required: true,
    },
    showVisualReviewApp: {
      type: Boolean,
      required: false,
      default: false,
    },
    visualReviewAppMeta: {
      type: Object,
      required: false,
      default: () => ({
        sourceProjectId: '',
        sourceProjectPath: '',
        mergeRequestId: '',
        appUrl: '',
      }),
    },
  },
  computed: {
    computedDeploymentStatus() {
      if (this.deployment.status === 'created') {
        return this.deployment.isManual ? 'manual_deploy' : 'will_deploy';
      }
      return this.deployment.status;
    },
    hasExternalUrls() {
      return Boolean(this.deployment.external_url && this.deployment.external_url_formatted);
    },
    hasPreviousDeployment() {
      return Boolean(!this.isCurrent && this.deployment.deployed_at);
    },
    isCurrent() {
      return this.computedDeploymentStatus === 'success';
    },
    isManual() {
      return Boolean(this.deployment.deployment_manual_actions.length > 0);
    },
    isDeployInProgress() {
      return this.deployment.status === 'running';
    },
    isRedeployable() {
      return this.isManual;
      // return this.isManual && this.deployment.status === 'failed';
    },
    playPath() {
      return this.isManual ? this.deployment.deployment_manual_actions[0].play_path : '' ;
    },
    retryPath() {
      return this.isRedeployable ? this.deployment.deployment_manual_actions[0].retry_path : '';
    },
    shouldRenderDropdown() {
      return this.deployment.changes && this.deployment.changes.length > 1;
    },
  },
};
</script>

<template>
  <div class="deploy-heading">
    <div class="ci-widget media">
      <div class="media-body">
        <div class="deploy-body">
          <deployment-info
            :computed-deployment-status="computedDeploymentStatus"
            :deployment="deployment"
            :show-metrics="showMetrics">
          </deployment-info>
          <div>
            <!-- if manual deploy, show deploy -->
            <deployment-manual-button
              v-if="isManual"
              :is-deploy-in-progress="isDeployInProgress"
              :play-path="playPath"
            />
            <!-- if it is failed, show re-deploy -->
            <deployment-redeploy-button
              v-if="isRedeployable"
              :is-deploy-in-progress="isDeployInProgress"
              :retry-path="retryPath"
            />
            <!-- show appropriate version of review app button  -->
            <deployment-view-button
              v-if="hasExternalUrls"
              :is-current="isCurrent"
              :deployment="deployment"
              :show-visual-review-app="showVisualReviewApp"
              :visual-review-app-metadata="visualReviewAppMeta"
            />
            <!-- if it is stoppable, show stop -->
            <deployment-stop-button
              v-if="deployment.stop_url"
              :is-deploy-in-progress="isDeployInProgress"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
