<script>
import { GlButton, GlFormGroup, GlModal, GlModalDirective, GlSegmentedControl } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { DELETE_MODAL_CONFIG, EDITOR_MODES, EditorModeRule, EditorModeYAML } from './constants';

export default {
  i18n: {
    DELETE_MODAL_CONFIG,
  },
  components: {
    GlButton,
    GlFormGroup,
    GlModal,
    GlSegmentedControl,
    PolicyYamlEditor: () =>
      import(/* webpackChunkName: 'policy_yaml_editor' */ '../policy_yaml_editor.vue'),
  },
  directives: { GlModal: GlModalDirective },
  inject: ['threatMonitoringPath'],
  props: {
    customSaveButtonText: {
      type: String,
      required: false,
      default: '',
    },
    defaultEditorMode: {
      type: String,
      required: false,
      default: EditorModeRule,
    },
    editorModes: {
      type: Array,
      required: false,
      default: () => EDITOR_MODES,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdatingPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
    policyName: {
      type: String,
      required: false,
      default: '',
    },
    yamlEditorValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selectedEditorMode: this.defaultEditorMode,
    };
  },
  computed: {
    deleteModalTitle() {
      return sprintf(s__('NetworkPolicies|Delete policy: %{policy}'), { policy: this.policyName });
    },
    saveButtonText() {
      if (this.customSaveButtonText) {
        return this.customSaveButtonText;
      }
      return this.isEditing
        ? s__('NetworkPolicies|Save changes')
        : s__('NetworkPolicies|Create policy');
    },
    shouldShowRuleEditor() {
      return this.selectedEditorMode === EditorModeRule;
    },
    shouldShowYamlEditor() {
      return this.selectedEditorMode === EditorModeYAML;
    },
  },
  methods: {
    removePolicy() {
      this.$emit('remove-policy');
    },
    savePolicy() {
      this.$emit('save-policy', this.selectedEditorMode);
    },
    updateEditorMode(mode) {
      this.selectedEditorMode = mode;
      this.$emit('update-editor-mode', mode);
    },
    updateYaml() {
      this.$emit('load-yaml');
    },
  },
};
</script>

<template>
  <section>
    <div class="gl-mb-5 gl-border-1 gl-border-solid gl-border-gray-100 gl-rounded-base">
      <gl-form-group
        class="gl-px-5 gl-py-3 gl-mb-0 gl-bg-gray-10 gl-border-b-solid gl-border-b-gray-100 gl-border-b-1"
      >
        <gl-segmented-control
          data-testid="editor-mode"
          :options="editorModes"
          :checked="selectedEditorMode"
          @input="updateEditorMode"
        />
      </gl-form-group>
      <div class="gl-display-flex gl-sm-flex-direction-column">
        <section class="gl-w-full gl-p-5 gl-flex-fill-4 policy-table-left">
          <slot v-if="shouldShowRuleEditor" name="rule-editor" data-testid="rule-editor"></slot>
          <policy-yaml-editor
            v-if="shouldShowYamlEditor"
            data-testid="policy-yaml-editor"
            :value="yamlEditorValue"
            :read-only="false"
            @input="updateYaml"
          />
        </section>
        <section
          v-if="shouldShowRuleEditor"
          class="gl-w-30p gl-p-5 gl-border-l-gray-100 gl-border-l-1 gl-border-l-solid gl-flex-fill-2"
        >
          <slot name="rule-editor-preview"></slot>
        </section>
      </div>
    </div>
    <gl-button
      type="submit"
      variant="success"
      data-testid="save-policy"
      :loading="isUpdatingPolicy"
      @click="savePolicy"
      >{{ saveButtonText }}</gl-button
    >
    <gl-button
      v-if="isEditing"
      v-gl-modal="'delete-modal'"
      category="secondary"
      variant="danger"
      data-testid="delete-policy"
      :loading="isRemovingPolicy"
      >{{ s__('NetworkPolicies|Delete policy') }}</gl-button
    >
    <gl-button category="secondary" :href="threatMonitoringPath">{{ __('Cancel') }}</gl-button>
    <gl-modal
      modal-id="delete-modal"
      :title="deleteModalTitle"
      :action-secondary="$options.i18n.DELETE_MODAL_CONFIG.secondary"
      :action-cancel="$options.i18n.DELETE_MODAL_CONFIG.cancel"
      @secondary="removePolicy"
    >
      {{
        s__(
          'NetworkPolicies|Are you sure you want to delete this policy? This action cannot be undone.',
        )
      }}
    </gl-modal>
  </section>
</template>
