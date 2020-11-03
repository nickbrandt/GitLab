<script>
import { GlIcon, GlLink, GlModal } from '@gitlab/ui';
import { JOB_RETRY_FORWARD_DEPLOYMENT_MODAL } from '../constants';

export default {
  name: 'JobRetryForwardDeploymentModal',
  components: {
    GlIcon,
    GlLink,
    GlModal,
  },
  i18n: {
    ...JOB_RETRY_FORWARD_DEPLOYMENT_MODAL,
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
  inject: {
    retryOutdatedJobDocsUrl: {
      default: '',
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
      <gl-link v-if="retryOutdatedJobDocsUrl" :href="retryOutdatedJobDocsUrl" target="_blank">
        <gl-icon name="question" />
      </gl-link>
    </gl-modal>
  </span>
</template>
