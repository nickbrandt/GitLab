<script>
import _ from 'underscore';
import { s__, sprintf } from '~/locale';
import { GlButton, GlModal, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    GlModal,
    Icon,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    deleteFeatureFlagUrl: {
      type: String,
      required: true,
    },
    featureFlagName: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
  },
  computed: {
    message() {
      return sprintf(
        s__('FeatureFlags|Feature flag %{name} will be removed. Are you sure?'),
        {
          name: _.escape(this.featureFlagName),
        },
        false,
      );
    },
    title() {
      return sprintf(
        s__('FeatureFlags|Delete %{name}?'),
        {
          name: _.escape(this.featureFlagName),
        },
        false,
      );
    },
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <div class="d-inline-block">
    <gl-button
      v-gl-tooltip.hover.bottom="__('Delete')"
      v-gl-modal-directive="modalId"
      class="js-feature-flag-delete-button"
      variant="danger"
    >
      <icon name="remove" :size="16" />
    </gl-button>
    <gl-modal
      :title="title"
      :ok-title="s__('FeatureFlags|Delete feature flag')"
      :modal-id="modalId"
      title-tag="h4"
      ok-variant="danger"
      @ok="onSubmit"
    >
      {{ message }}
      <form ref="form" :action="deleteFeatureFlagUrl" method="post" class="js-requires-input">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
