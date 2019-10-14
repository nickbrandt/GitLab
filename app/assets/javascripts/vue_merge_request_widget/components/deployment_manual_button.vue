<script>
import { __ } from '~/locale';
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingButton from '../../vue_shared/components/loading_button.vue';

export default {
  name: 'DeploymentManualButton',
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
    playPath: {
      type: String,
      required: true,
    }
  },
  computed: {
    deployButtonText() {
      return __('Deploy manually');
    }
  },
  methods: {
    handleManualDeploy() {
      console.log('manual deploy was clicked', this.playPath);
    }
  },
}
</script>

<template>
  <loading-button
    v-gl-tooltip
    :title="deployButtonText"
    :loading="isDeployInProgress"
    :disabled="isDeployInProgress"
    container-class="btn btn-default btn-retry btn-sm"
    @click="handleManualDeploy"
  >
    <icon name="play" />
  </loading-button>
</template>
