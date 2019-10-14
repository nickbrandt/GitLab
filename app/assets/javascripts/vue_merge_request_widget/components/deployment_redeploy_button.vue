<script>
import { __ } from '~/locale';
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingButton from '../../vue_shared/components/loading_button.vue';

export default {
  name: 'DeploymentRedeployButton',
  components: {
    LoadingButton,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isDeployInProgress: {
      type: Boolean,
      required: true,
    },
    retryPath: {
      type: String,
      required: true,
    }
  },
  computed: {
    redeployButtonText() {
      return __('Re-deploy to environment');
    }
  },
  methods: {
    handleRedeploy() {
      console.log('redeploy was clicked', this.retryPath);
    }
  },

}
</script>

<template>
  <loading-button
    v-gl-tooltip
    :title="redeployButtonText"
    :loading="isDeployInProgress"
    :disabled="isDeployInProgress"
    container-class="btn btn-default btn-retry btn-sm"
    @click="handleRedeploy"
  >
    <icon name="repeat" />
  </loading-button>
</template>
