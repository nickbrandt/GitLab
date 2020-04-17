<script>
import { GlTooltip } from '@gitlab/ui';

export default {
  components: {
    GlTooltip,
  },
  props: {
    healthStatus: {
      type: Object,
      required: true,
      default: () => {},
    },
  },
};
</script>

<template>
  <div ref="healthStatus" class="health-status d-inline-flex align-items-center">
    <gl-tooltip :target="() => $refs.healthStatus" placement="top">
      <span
        ><strong>{{ healthStatus.issuesOnTrack }}</strong
        >&nbsp;<span>{{ __('issues on track') }}</span
        >,</span
      ><br />
      <span
        ><strong>{{ healthStatus.issuesNeedingAttention }}</strong
        >&nbsp;<span>{{ __('issues need attention') }}</span
        >,</span
      ><br />
      <span
        ><strong>{{ healthStatus.issuesAtRisk }}</strong
        >&nbsp;<span>{{ __('issues at risk') }}</span></span
      >
    </gl-tooltip>

    <span class="gl-label gl-label-text-dark gl-label-sm status-on-track"
      ><span class="gl-label-text">
        {{ healthStatus.issuesOnTrack }}
      </span></span
    >
    <span class="ml-1 mr-1 mr-md-2 text-secondary health-label-long">{{
      __('issues on track')
    }}</span>
    <span class="ml-1 mr-1 mr-md-2 text-secondary text-truncate health-label-short">{{
      __('on track')
    }}</span>

    <span class="gl-label gl-label-text-dark gl-label-sm status-needs-attention"
      ><span class="gl-label-text">
        {{ healthStatus.issuesNeedingAttention }}
      </span></span
    >
    <span class="ml-1 mr-1 mr-md-2 text-secondary health-label-long">{{
      __('issues need attention')
    }}</span>
    <span class="ml-1 mr-1 mr-md-2 text-secondary text-truncate health-label-short">{{
      __('need attention')
    }}</span>

    <span class="gl-label gl-label-text-dark gl-label-sm status-at-risk"
      ><span class="gl-label-text">
        {{ healthStatus.issuesAtRisk }}
      </span></span
    >
    <span class="ml-1 text-secondary health-label-long">{{ __('issues at risk') }}</span>
    <span class="ml-1 text-secondary text-truncate health-label-short">{{ __('at risk') }}</span>
  </div>
</template>
