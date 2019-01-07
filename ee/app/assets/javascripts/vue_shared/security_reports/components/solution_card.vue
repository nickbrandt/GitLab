<script>
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'SolutionCard',
  components: { GlButton, Icon },
  props: {
    solution: {
      type: String,
      default: '',
    },
    remediation: {
      type: Object,
      default: null,
    },
  },
  computed: {
    solutionText() {
      return (this.remediation && this.remediation.summary) || this.solution;
    },
    remediationDiff() {
      return this.remediation && this.remediation.diff;
    },
    downloadUrl() {
      return `data:text/plain;base64,${this.remediationDiff}`;
    },
    hasDiff() {
      return (this.remediationDiff && this.remediationDiff.length > 0) || false;
    },
  },
};
</script>
<template>
  <div class="card js-solution-card my-4">
    <div class="card-body d-flex align-items-center">
      <div class="col-2 d-flex align-items-center pl-0">
        <div class="circle-icon-container" aria-hidden="true"><icon name="bulb" /></div>
        <strong class="text-right flex-grow-1">{{ s__('ciReport|Solution') }}:</strong>
      </div>
      <span class="col-10 flex-shrink-1 pl-0">{{ solutionText }}</span>
      <gl-button v-if="hasDiff" :href="downloadUrl" download="remediation.patch">
        <icon name="download" /> {{ s__('ciReport|Download patch') }}
      </gl-button>
    </div>
    <div v-if="hasDiff" class="card-footer">
      <em class="text-secondary">
        {{ s__('ciReport|Download and apply the patch to fix this vulnerability.') }}
      </em>
    </div>
  </div>
</template>
