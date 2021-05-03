<script>
import { ContentEditor } from '../services/content_editor';
// import Divider from './divider.vue';
import ToolbarButton from './toolbar_button.vue';

export default {
  components: {
    ToolbarButton,
    // Divider,
  },
  props: {
    contentEditor: {
      type: ContentEditor,
      required: true,
    },
    toolbarState: {
      type: Object,
      required: true,
    },
    toolbarButtons: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-justify-content-end gl-pb-3 gl-pt-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-200"
  >
    <toolbar-button
      v-for="button in toolbarButtons"
      :key="button.contentType"
      :content-type="button.contentType"
      :icon-name="button.iconName"
      :editor-command="button.editorCommand"
      :label="button.label"
      :is-active="toolbarState[button.contentType].isActive"
      :tiptap-editor="contentEditor.tiptapEditor"
    />
  </div>
</template>
