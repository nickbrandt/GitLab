<script>
import { GlModal, GlButton } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  modalTitle: s__('FeatureFlags|Configure feature flags'),
  apiUrlLabelText: s__('FeatureFlags|API URL'),
  apiUrlCopyText: __('Copy URL to clipboard'),
  instanceIdLabelText: s__('FeatureFlags|Instance ID'),
  instanceIdCopyText: __('Copy ID to clipboard'),

  components: {
    GlModal,
    GlButton,
    ModalCopyButton,
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
  },

  computed: {
    helpText() {
      return sprintf(
        s__(
          'FeatureFlags|Install a %{docs_link_anchored_start}compatible client library%{docs_link_anchored_end} and specify the API URL, application name, and instance ID during the configuration setup. %{docs_link_start}More Information%{docs_link_end}',
        ),
        {
          docs_link_anchored_start: `<a href="${this.helpAnchor}">`,
          docs_link_anchored_end: '</a>',
          docs_link_start: `<a href="${this.helpPath}">`,
          docs_link_end: '</a>',
        },
        false,
      );
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
            class="input-group-text btn btn-default"
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
        />
        <span class="input-group-append">
          <modal-copy-button
            :text="instanceId"
            :title="$options.instanceIdCopyText"
            :modal-id="modalId"
            class="input-group-text btn btn-default"
          />
        </span>
      </div>
    </div>
  </gl-modal>
</template>
