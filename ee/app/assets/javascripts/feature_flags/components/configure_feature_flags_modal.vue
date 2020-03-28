<script>
import { GlModal, GlButton, GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import Callout from '~/vue_shared/components/callout.vue';

export default {
  modalTitle: s__('FeatureFlags|Configure feature flags'),
  apiUrlLabelText: s__('FeatureFlags|API URL'),
  apiUrlCopyText: __('Copy URL'),
  instanceIdLabelText: s__('FeatureFlags|Instance ID'),
  instanceIdCopyText: __('Copy ID'),
  regenerateInstanceIdTooltip: __('Regenerate instance ID'),
  instanceIdRegenerateError: __('Unable to generate new instance ID'),
  instanceIdRegenerateText: __(
    'Regenerating the instance ID can break integration depending on the client you are using.',
  ),

  components: {
    GlModal,
    GlButton,
    ModalCopyButton,
    Icon,
    Callout,
    GlLoadingIcon,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    helpPath: {
      type: String,
      required: true,
    },
    helpAnchor: {
      type: String,
      required: true,
    },
    apiUrl: {
      type: String,
      required: true,
    },
    instanceId: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: false,
      default: 'configure-feature-flags',
    },
    isRotating: {
      type: Boolean,
      required: true,
    },
    hasRotateError: {
      type: Boolean,
      required: true,
    },
    canUserRotateToken: {
      type: Boolean,
      required: true,
    },
  },

  computed: {
    helpText() {
      return sprintf(
        s__(
          'FeatureFlags|Install a %{docs_link_anchored_start}compatible client library%{docs_link_anchored_end} and specify the API URL, application name, and instance ID during the configuration setup. %{docs_link_start}More Information%{docs_link_end}',
        ),
        {
          docs_link_anchored_start: `<a href="${this.helpAnchor}" target="_blank">`,
          docs_link_anchored_end: '</a>',
          docs_link_start: `<a href="${this.helpPath}" target="_blank">`,
          docs_link_end: '</a>',
        },
        false,
      );
    },
  },

  methods: {
    rotateToken() {
      this.$emit('token');
    },
  },
};
</script>
<template>
  <gl-modal :modal-id="modalId" :hide-footer="true">
    <template #modal-title>
      {{ $options.modalTitle }}
    </template>
    <p v-html="helpText"></p>
    <div class="form-group">
      <label for="api_url" class="label-bold">{{ $options.apiUrlLabelText }}</label>
      <div class="input-group">
        <input
          id="api_url"
          :value="apiUrl"
          readonly
          class="form-control"
          type="text"
          name="api_url"
        />
        <span class="input-group-append">
          <modal-copy-button
            :text="apiUrl"
            :title="$options.apiUrlCopyText"
            :modal-id="modalId"
            class="input-group-text"
          />
        </span>
      </div>
    </div>
    <div class="form-group">
      <label for="instance_id" class="label-bold">{{ $options.instanceIdLabelText }}</label>
      <div class="input-group">
        <input
          id="instance_id"
          :value="instanceId"
          class="form-control"
          type="text"
          name="instance_id"
          readonly
          :disabled="isRotating"
        />

        <gl-loading-icon
          v-if="isRotating"
          class="position-absolute align-self-center instance-id-loading-icon"
        />

        <div class="input-group-append">
          <gl-button
            v-if="canUserRotateToken"
            v-gl-tooltip.hover
            :title="$options.regenerateInstanceIdTooltip"
            class="input-group-text"
            @click="rotateToken"
          >
            <icon name="retry" />
          </gl-button>
          <modal-copy-button
            :text="instanceId"
            :title="$options.instanceIdCopyText"
            :modal-id="modalId"
            :disabled="isRotating"
            class="input-group-text"
          />
        </div>
      </div>
    </div>
    <div
      v-if="hasRotateError"
      class="text-danger d-flex align-items-center font-weight-normal mb-2"
    >
      <icon name="warning" class="mr-1" />
      <span>{{ $options.instanceIdRegenerateError }}</span>
    </div>
    <callout
      v-if="canUserRotateToken"
      category="info"
      :message="$options.instanceIdRegenerateText"
    />
  </gl-modal>
</template>
