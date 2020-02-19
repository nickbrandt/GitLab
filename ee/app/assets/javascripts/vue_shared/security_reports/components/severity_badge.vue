<script>
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { spriteIcon } from '~/lib/utils/common_utils';


export default {
  name: 'SeverityBadge',
  props: {
    severity: {
      type: String,
      required: true,
    },
  },
  computed: {
    className() {
      return `severity-badge-${this.severity.toLowerCase()}`;
    },
    severityTitle() {
      return SEVERITY_LEVELS[this.severity] || this.severity;
    },
    iconHtml() {
      return spriteIcon('severity-'+this.severity.toLowerCase());
    },    
  },
};
</script>

<template>
  <div class="severity-badge"><span v-html="iconHtml" :class="className"></span> {{ severityTitle }}</div>
</template>

<style>
.severity-badge {
  display: inline-block;
  font-size: 0.9em;
  padding: 0.6em 0.4em 0.4em;
}

.severity-badge svg {
    height:12px;
    width:12px;
    margin-right:4px;
    position:relative;
    top:1px;
}

.severity-badge-critical {
  color: #8B2615;
}

.severity-badge-high {
  color: #C0341D;
}

.severity-badge-medium {
  color: #FCA429;
}

.severity-badge-low {
  color: #FDBC60;
}

.severity-badge-info {
  color: #418CD8;
}

.severity-badge-unknown {
  color: #919191;
}
</style>
