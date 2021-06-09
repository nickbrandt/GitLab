<script>
import { __ } from '~/locale';
import { EDITOR_MODES, EditorModeYAML } from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import { DEFAULT_SCAN_EXECUTION_POLICY, fromYaml } from './lib';

export default {
  DEFAULT_EDITOR_MODE: EditorModeYAML,
  EDITOR_MODES: [EDITOR_MODES[1]],
  i18n: {
    createMergeRequest: __('Create merge request'),
  },
  components: {
    PolicyEditorLayout,
  },
  inject: ['threatMonitoringPath', 'projectId'],
  props: {
    existingPolicy: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    const policy = this.existingPolicy
      ? fromYaml(this.existingPolicy.manifest)
      : fromYaml(DEFAULT_SCAN_EXECUTION_POLICY);

    const yamlEditorValue = this.existingPolicy
      ? this.existingPolicy.manifest
      : DEFAULT_SCAN_EXECUTION_POLICY;

    return {
      editorMode: EditorModeYAML,
      yamlEditorValue,
      yamlEditorError: policy.error ? true : null,
      policy,
    };
  },
  computed: {
    isCreatingMergeRequest() {
      // TODO track the graphql mutation status after #333163 is closed
      return false;
    },
    isEditing() {
      return Boolean(this.existingPolicy);
    },
  },
  methods: {
    createMergeRequest() {
      // TODO call graphql mutation and redirect to merge request after #333163 is closed
    },
  },
};
</script>

<template>
  <policy-editor-layout
    :custom-save-button-text="$options.i18n.createMergeRequest"
    :default-editor-mode="$options.DEFAULT_EDITOR_MODE"
    :editor-modes="$options.EDITOR_MODES"
    :is-editing="isEditing"
    :is-updating-policy="isCreatingMergeRequest"
    :policy-name="policy.name"
    :yaml-editor-value="yamlEditorValue"
    @save-policy="createMergeRequest"
  />
</template>
