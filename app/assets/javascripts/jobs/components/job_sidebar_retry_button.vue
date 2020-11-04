<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { JOB_SIDEBAR } from '../constants';

export default {
  name: 'JobSidebarRetryButton',
  i18n: {
    retryLabel: JOB_SIDEBAR.retry,
  },
  components: {
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    category: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: 'info',
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
  },
};
</script>
<template>
  <gl-button
    v-if="hasForwardDeploymentFailure"
    v-gl-modal="modalId"
    :aria-label="$options.i18n.retryLabel"
    category="primary"
    variant="info"
    >{{ $options.i18n.retryLabel }}</gl-button
  >
  <gl-button
    v-else
    :href="href"
    :category="category"
    :variant="variant"
    data-method="post"
    rel="nofollow"
    >{{ $options.i18n.retryLabel }}
  </gl-button>
</template>
