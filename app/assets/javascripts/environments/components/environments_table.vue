<script>
/**
 * Render environments table.
 */
import { GlLoadingIcon } from '@gitlab/ui';
import environmentItem from './environment_item.vue'; // eslint-disable-line import/order

// ee-only start
import deployBoard from 'ee/environments/components/deploy_board_component.vue';
import CanaryDeploymentCallout from 'ee/environments/components/canary_deployment_callout.vue';
// ee-only end

export default {
  components: {
    environmentItem,
    deployBoard,
    GlLoadingIcon,
    // ee-only start
    CanaryDeploymentCallout,
    // ee-only end
  },

  props: {
    environments: {
      type: Array,
      required: true,
      default: () => [],
    },

    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },

    // ee-only start
    canaryDeploymentFeatureId: {
      type: String,
      required: true,
    },

    showCanaryDeploymentCallout: {
      type: Boolean,
      required: true,
    },

    userCalloutsPath: {
      type: String,
      required: true,
    },

    lockPromotionSvgPath: {
      type: String,
      required: true,
    },

    helpCanaryDeploymentsPath: {
      type: String,
      required: true,
    },
    // ee-only end
  },
  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
    shouldRenderFolderContent(env) {
      return env.isFolder && env.isOpen && env.children && env.children.length > 0;
    },
    // ee-only start
    shouldShowCanaryCallout(env) {
      return env.showCanaryCallout && this.showCanaryDeploymentCallout;
    },
    // ee-only end
  },
};
</script>
<template>
  <div class="ci-table" role="grid">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-15 environments-name" role="columnheader">
        {{ s__('Environments|Environment') }}
      </div>
      <div class="table-section section-10 environments-deploy" role="columnheader">
        {{ s__('Environments|Deployment') }}
      </div>
      <div class="table-section section-15 environments-build" role="columnheader">
        {{ s__('Environments|Job') }}
      </div>
      <div class="table-section section-20 environments-commit" role="columnheader">
        {{ s__('Environments|Commit') }}
      </div>
      <div class="table-section section-10 environments-date" role="columnheader">
        {{ s__('Environments|Updated') }}
      </div>
    </div>
    <template v-for="(model, i) in environments" :model="model">
      <div
        is="environment-item"
        :key="`environment-item-${i}`"
        :model="model"
        :can-read-environment="canReadEnvironment"
      />

      <div
        v-if="model.hasDeployBoard && model.isDeployBoardVisible"
        :key="`deploy-board-row-${i}`"
        class="js-deploy-board-row"
      >
        <div class="deploy-board-container">
          <deploy-board
            :deploy-board-data="model.deployBoardData"
            :is-loading="model.isLoadingDeployBoard"
            :is-empty="model.isEmptyDeployBoard"
            :logs-path="model.logs_path"
          />
        </div>
      </div>

      <template v-if="shouldRenderFolderContent(model)">
        <div v-if="model.isLoadingFolderContent" :key="`loading-item-${i}`">
          <gl-loading-icon :size="2" class="prepend-top-16" />
        </div>

        <template v-else>
          <div
            is="environment-item"
            v-for="(children, index) in model.children"
            :key="`env-item-${i}-${index}`"
            :model="children"
            :can-read-environment="canReadEnvironment"
          />

          <div :key="`sub-div-${i}`">
            <div class="text-center prepend-top-10">
              <a :href="folderUrl(model)" class="btn btn-default">{{
                s__('Environments|Show all')
              }}</a>
            </div>
          </div>
        </template>
      </template>

      <template v-if="shouldShowCanaryCallout(model)">
        <canary-deployment-callout
          :key="`canary-promo-${i}`"
          :canary-deployment-feature-id="canaryDeploymentFeatureId"
          :user-callouts-path="userCalloutsPath"
          :lock-promotion-svg-path="lockPromotionSvgPath"
          :help-canary-deployments-path="helpCanaryDeploymentsPath"
          :data-js-canary-promo-key="i"
        />
      </template>
    </template>
  </div>
</template>
