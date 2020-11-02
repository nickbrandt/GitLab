<script>
import { GlModal } from '@gitlab/ui';
import { JOBS_RETRY_FORWARD_DEPLOYMENT_MODAL } from '../constants';

export default {
  name: 'JobRetryForwardDeploymentModal',
  components: {
    GlModal,
  },
  i18n: {
    ...JOBS_RETRY_FORWARD_DEPLOYMENT_MODAL,
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      primaryProps: {
        text: this.$options.i18n.primaryText,
        attributes: [
          {
            'data-method': 'post',
            'data-testid': 'retry-button-modal',
            href: this.href,
            variant: 'danger',
          },
        ],
      },
      cancelProps: {
        text: this.$options.i18n.cancel,
        attributes: [{ category: 'secondary', variant: 'default' }],
      },
    };
  },
};
</script>

<template>
  <span>
    <gl-modal
      :action-cancel="cancelProps"
      :action-primary="primaryProps"
      :modal-id="modalId"
      :title="$options.i18n.title"
    >
      {{ $options.i18n.body }}
    </gl-modal>
  </span>
</template>
