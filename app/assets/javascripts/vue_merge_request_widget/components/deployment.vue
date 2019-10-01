<script>
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import FilteredSearchDropdown from '~/vue_shared/components/filtered_search_dropdown.vue';
import { __ } from '~/locale';
import LoadingButton from '../../vue_shared/components/loading_button.vue';
import { visitUrl } from '../../lib/utils/url_utility';
import createFlash from '../../flash';
import MRWidgetService from '../services/mr_widget_service';
import DeploymentInfo from './deployment_info.vue'
import ReviewAppLink from './review_app_link.vue';

export default {
  // name: 'Deployment' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'Deployment',
  components: {
    DeploymentInfo,
    LoadingButton,
    Icon,
    FilteredSearchDropdown,
    ReviewAppLink,
    VisualReviewAppLink: () =>
      import('ee_component/vue_merge_request_widget/components/visual_review_app_link.vue'),
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
  data() {
    return {
      isStopping: false,
    };
  },
  computed: {
    computedDeploymentStatus() {
      if (this.deployment.status === 'created') {
        return this.deployment.isManual ? 'manual_deploy' : 'will_deploy';
      }
      return this.deployment.status
    },
    deploymentExternalUrl() {
      if (this.deployment.changes && this.deployment.changes.length === 1) {
        return this.deployment.changes[0].external_url;
      }
      return this.deployment.external_url;
    },
    hasExternalUrls() {
      return Boolean(this.deployment.external_url && this.deployment.external_url_formatted);
    },
    isDeployInProgress() {
      return this.deployment.status === 'running';
    },
    deployInProgressTooltip() {
      return this.isDeployInProgress
        ? __('Stopping this environment is currently not possible as a deployment is in progress')
        : '';
    },
    shouldRenderDropdown() {
      return this.deployment.changes && this.deployment.changes.length > 1;
    },
  },
  methods: {
    stopEnvironment() {
      const msg = __('Are you sure you want to stop this environment?');
      const isConfirmed = confirm(msg); // eslint-disable-line

      if (isConfirmed) {
        this.isStopping = true;

        MRWidgetService.stopEnvironment(this.deployment.stop_url)
          .then(res => res.data)
          .then(data => {
            if (data.redirect_url) {
              visitUrl(data.redirect_url);
            }

            this.isStopping = false;
          })
          .catch(() => {
            createFlash(
              __('Something went wrong while stopping this environment. Please try again.'),
            );
            this.isStopping = false;
          });
      }
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
            <template v-if="hasExternalUrls">
              <filtered-search-dropdown
                v-if="shouldRenderDropdown"
                class="js-mr-wigdet-deployment-dropdown inline"
                :items="deployment.changes"
                :main-action-link="deploymentExternalUrl"
                filter-key="path"
              >
                <template slot="mainAction" slot-scope="slotProps">
                  <review-app-link
                    :link="deploymentExternalUrl"
                    :css-class="`deploy-link js-deploy-url inline ${slotProps.className}`"
                  />
                </template>

                <template slot="result" slot-scope="slotProps">
                  <a
                    :href="slotProps.result.external_url"
                    target="_blank"
                    rel="noopener noreferrer nofollow"
                    class="menu-item"
                  >
                    <strong class="str-truncated-100 append-bottom-0 d-block">
                      {{ slotProps.result.path }}
                    </strong>

                    <p class="text-secondary str-truncated-100 append-bottom-0 d-block">
                      {{ slotProps.result.external_url }}
                    </p>
                  </a>
                </template>
              </filtered-search-dropdown>
              <template v-else>
                <review-app-link
                  :link="deploymentExternalUrl"
                  css-class="js-deploy-url deploy-link btn btn-default btn-sm inline"
                />
              </template>
              <visual-review-app-link
                v-if="showVisualReviewApp"
                :link="deploymentExternalUrl"
                :app-metadata="visualReviewAppMeta"
              />
            </template>
            <span
              v-if="deployment.stop_url"
              v-gl-tooltip
              :title="deployInProgressTooltip"
              class="d-inline-block"
              tabindex="0"
            >
              <loading-button
                :loading="isStopping"
                :disabled="isDeployInProgress"
                :title="__('Stop environment')"
                container-class="js-stop-env btn btn-default btn-sm inline prepend-left-4"
                @click="stopEnvironment"
              >
                <icon name="stop" />
              </loading-button>
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
